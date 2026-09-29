import Foundation

struct AdsResearchResult {
    let platform: AdPlatform
    var status: AdStatus
    var adCount: Int?
    var summary: String
    var lastSeen: String?
    var isLoading: Bool

    enum AdStatus {
        case running       // Actively running ads
        case notFound      // No ads found
        case unknown       // Could not determine
        case error         // Request failed
    }
}

enum AdPlatform: String, CaseIterable {
    case appleSearchAds = "Apple Search Ads"
    case meta           = "Meta (Facebook/Instagram)"
    case tiktok         = "TikTok"

    var icon: String {
        switch self {
        case .appleSearchAds: return "applelogo"
        case .meta:           return "f.square.fill"
        case .tiktok:         return "music.note"
        }
    }

    var color: String {
        switch self {
        case .appleSearchAds: return "blue"
        case .meta:           return "indigo"
        case .tiktok:         return "pink"
        }
    }

    var searchURL: String {
        switch self {
        case .appleSearchAds: return "https://adrepository.apple.com"
        case .meta:           return "https://www.facebook.com/ads/library"
        case .tiktok:         return "https://library.tiktok.com"
        }
    }
}

struct AdsResearchService {
    private static let apiKey   = Config.kieAPIKey
    private static let endpoint = Config.kieAPIEndpoint

    // Search all 3 platforms in parallel
    static func searchAllPlatforms(appName: String, developerName: String) async -> [AdPlatform: AdsResearchResult] {
        var results: [AdPlatform: AdsResearchResult] = [:]

        await withTaskGroup(of: (AdPlatform, AdsResearchResult).self) { group in
            for platform in AdPlatform.allCases {
                group.addTask {
                    let result = await search(appName: appName, developerName: developerName, platform: platform)
                    return (platform, result)
                }
            }
            for await (platform, result) in group {
                results[platform] = result
            }
        }
        return results
    }

    // Search a single platform
    static func search(appName: String, developerName: String, platform: AdPlatform) async -> AdsResearchResult {
        let prompt = buildPrompt(appName: appName, developerName: developerName, platform: platform)

        let body: [String: Any] = [
            "model": "gpt-5-5",
            "stream": false,
            "reasoning": ["effort": "low"],
            "input": [
                ["role": "user", "content": [["type": "input_text", "text": prompt]]]
            ],
            "tools": [["type": "web_search"]]
        ]

        guard let reqURL = URL(string: endpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return AdsResearchResult(platform: platform, status: .error, summary: "Request failed", isLoading: false)
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 90
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)

        var request = URLRequest(url: reqURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, resp) = try await session.data(for: request)

            if let http = resp as? HTTPURLResponse {
                print("[\(platform.rawValue)] HTTP \(http.statusCode)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return AdsResearchResult(platform: platform, status: .error, summary: "Invalid response", isLoading: false)
            }

            if let code = json["code"] as? Int, code != 200 {
                let msg = json["msg"] as? String ?? "Server error"
                print("[\(platform.rawValue)] Error \(code): \(msg)")
                return AdsResearchResult(platform: platform, status: .error, summary: msg, isLoading: false)
            }

            // Extract text from Responses API output
            var content = ""
            if let output = json["output"] as? [[String: Any]] {
                for item in output {
                    guard item["type"] as? String == "message",
                          let contentArr = item["content"] as? [[String: Any]] else { continue }
                    let text = contentArr
                        .filter { $0["type"] as? String == "output_text" }
                        .compactMap { $0["text"] as? String }
                        .joined()
                    if !text.isEmpty { content = text; break }
                }
            }

            print("[\(platform.rawValue)] Response: \(content.prefix(300))")

            return parseResult(content: content, platform: platform)

        } catch {
            print("[\(platform.rawValue)] Error: \(error.localizedDescription)")
            return AdsResearchResult(platform: platform, status: .error, summary: error.localizedDescription, isLoading: false)
        }
    }

    // MARK: - Build search prompt per platform

    private static func buildPrompt(appName: String, developerName: String, platform: AdPlatform) -> String {
        switch platform {
        case .appleSearchAds:
            return """
            Search \(platform.searchURL) for ads from the app "\(appName)" by developer "\(developerName)".
            
            Tell me:
            1. Is this app currently running Apple Search Ads? (yes/no/unknown)
            2. If yes, approximately how many ads are visible?
            3. What keywords or ad creatives are shown?
            
            Return your answer as JSON:
            {"running": true/false/null, "ad_count": number_or_null, "summary": "brief description", "last_seen": "date if available or null"}
            """

        case .meta:
            return """
            Search \(platform.searchURL) for ads from "\(appName)" by "\(developerName)".
            Look for: active Facebook ads, Instagram ads from this app/developer.
            
            Tell me:
            1. Is this app running Meta (Facebook/Instagram) ads? (yes/no/unknown)
            2. How many active ads?
            3. What platforms (Facebook/Instagram) and what do the ads look like?
            
            Return your answer as JSON:
            {"running": true/false/null, "ad_count": number_or_null, "summary": "brief description", "last_seen": "date if available or null"}
            """

        case .tiktok:
            return """
            Search \(platform.searchURL) for ads from "\(appName)" by advertiser "\(developerName)".
            
            Tell me:
            1. Is this app running TikTok ads? (yes/no/unknown)
            2. How many active ads?
            3. What do the ads look like, what's the targeting?
            
            Return your answer as JSON:
            {"running": true/false/null, "ad_count": number_or_null, "summary": "brief description", "last_seen": "date if available or null"}
            """
        }
    }

    // MARK: - Parse GPT response

    private static func parseResult(content: String, platform: AdPlatform) -> AdsResearchResult {
        let stripped = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")

        // Find JSON object
        var depth = 0, start: String.Index? = nil, end: String.Index? = nil
        for idx in stripped.indices {
            switch stripped[idx] {
            case "{": if depth == 0 { start = idx }; depth += 1
            case "}": depth -= 1; if depth == 0, start != nil { end = idx }
            default: break
            }
            if end != nil { break }
        }

        guard let s = start, let e = end,
              let data = String(stripped[s...e]).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback: parse text response
            return parseTextFallback(content: content, platform: platform)
        }

        let running    = json["running"] as? Bool
        let adCount    = json["ad_count"] as? Int
        let summary    = json["summary"] as? String ?? content
        let lastSeen   = json["last_seen"] as? String

        let status: AdsResearchResult.AdStatus
        if let r = running {
            status = r ? .running : .notFound
        } else {
            status = .unknown
        }

        return AdsResearchResult(
            platform: platform,
            status: status,
            adCount: adCount,
            summary: summary,
            lastSeen: lastSeen,
            isLoading: false
        )
    }

    private static func parseTextFallback(content: String, platform: AdPlatform) -> AdsResearchResult {
        let lower = content.lowercased()
        let runningKeywords = ["running ads", "active ads", "found ads", "is advertising", "has ads", "ads found"]
        let notFoundKeywords = ["no ads", "not found", "not running", "no active", "couldn't find", "could not find"]

        if runningKeywords.contains(where: { lower.contains($0) }) {
            return AdsResearchResult(platform: platform, status: .running, summary: content, isLoading: false)
        } else if notFoundKeywords.contains(where: { lower.contains($0) }) {
            return AdsResearchResult(platform: platform, status: .notFound, summary: content, isLoading: false)
        }
        return AdsResearchResult(platform: platform, status: .unknown, summary: content, isLoading: false)
    }
}
