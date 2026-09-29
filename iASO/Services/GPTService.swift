import Foundation

struct AppStoreScrapedData {
    let subtitle: String
    let keywords: [String]
    let keywordsFromDescription: [String]
}

struct GPTService {
    private static let apiKey   = Config.kieAPIKey
    private static let endpoint = Config.kieAPIEndpoint

    // MARK: - Main entry
    static func scrapeAppStore(appId: Int, appName: String = "", country: String = "us", extractKeywords: Bool = true) async -> AppStoreScrapedData? {
        guard !Task.isCancelled else { return nil }

        async let ssrFetch    = fetchSubtitleFromSSR(appId: appId, appName: appName, country: country)
        async let itunesFetch = fetchiTunesData(appId: appId, country: country)

        let (ssrSubtitle, itunesData) = await (ssrFetch, itunesFetch)
        guard !Task.isCancelled else { return nil }

        let subtitle    = ssrSubtitle ?? itunesData?.subtitle ?? ""
        let description = itunesData?.description ?? ""

        print("[Scrape] Final subtitle: '\(subtitle)'")
        print("[Scrape] Description: \(description.count) chars")

        // GPT keyword extraction is optional — subtitle always fetched via URLSession
        if extractKeywords {
            let extracted = await extractKeywordsWithGPT(appName: appName, subtitle: subtitle, description: description)
            return AppStoreScrapedData(
                subtitle: subtitle,
                keywords: extracted?.keywords ?? [],
                keywordsFromDescription: extracted?.keywordsFromDescription ?? []
            )
        } else {
            print("[Scrape] GPT keyword extraction skipped")
            return AppStoreScrapedData(subtitle: subtitle, keywords: [], keywordsFromDescription: [])
        }
    }

    // MARK: - Fetch subtitle from App Store SSR page
    private static func fetchSubtitleFromSSR(appId: Int, appName: String, country: String) async -> String? {
        let slug = appName.isEmpty ? "app" : makeSlug(appName)
        let urlStr = "https://apps.apple.com/\(country)/app/\(slug)/id\(appId)"
        guard let url = URL(string: urlStr) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 20

        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            print("[SSR] Page: \(html.count) chars")

            // Try serialized-server-data first
            if let subtitle = parseSerializedServerData(html: html) {
                print("[SSR] Subtitle from serialized-server-data: '\(subtitle)'")
                return subtitle
            }

            // HTML fallbacks
            if let subtitle = parseSubtitleFromHTML(html: html) {
                print("[SSR] Subtitle from HTML fallback: '\(subtitle)'")
                return subtitle
            }

            print("[SSR] No subtitle found")
            return nil

        } catch {
            print("[SSR] Error: \(error.localizedDescription)")
            return nil
        }
    }

    // Parse serialized-server-data JSON — Apple's SSR data blob
    private static func parseSerializedServerData(html: String) -> String? {
        // Extract the script tag content
        guard let regex = try? NSRegularExpression(
            pattern: #"<script[^>]+id="serialized-server-data"[^>]*>([\s\S]*?)</script>"#
        ) else { return nil }

        let nsHtml = html as NSString
        guard let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: nsHtml.length)),
              match.numberOfRanges > 1 else { return nil }

        let scriptContent = nsHtml.substring(with: match.range(at: 1))
        print("[SSR] serialized-server-data: \(scriptContent.count) chars")

        guard let jsonData = scriptContent.data(using: .utf8) else { return nil }

        // The JSON is typically an array at the top level — handle any type
        do {
            let parsed = try JSONSerialization.jsonObject(with: jsonData, options: [])
            print("[SSR] JSON parsed successfully, walking for subtitle...")
            // Walk entire JSON tree looking for subtitle
            if let subtitle = walkForSubtitle(parsed) {
                return subtitle
            }
            print("[SSR] Subtitle not found in JSON tree")
            return nil
        } catch {
            print("[SSR] JSON parse error: \(error.localizedDescription)")
            // Try to fix common JSON issues and retry
            let fixed = scriptContent
                .replacingOccurrences(of: "\\/", with: "/")
            if let fixedData = fixed.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: fixedData, options: []) {
                return walkForSubtitle(parsed)
            }
            return nil
        }
    }

    // Walk ANY JSON structure (array, dict, nested) looking for subtitle
    private static func walkForSubtitle(_ json: Any, depth: Int = 0) -> String? {
        guard depth < 20 else { return nil } // prevent infinite recursion

        if let dict = json as? [String: Any] {
            // Check subtitle-related keys directly
            let subtitleKeys = ["subtitle", "artistSubtitle", "shortDescription"]
            for key in subtitleKeys {
                if let val = dict[key] as? String,
                   isValidSubtitle(val) {
                    return val
                }
            }
            // Check for kind == "subtitle" pattern
            if let kind = dict["kind"] as? String,
               kind.lowercased() == "subtitle",
               let label = dict["label"] as? String,
               isValidSubtitle(label) {
                return label
            }
            // Recurse into all values
            for (_, value) in dict {
                if let found = walkForSubtitle(value, depth: depth + 1) {
                    return found
                }
            }
        } else if let arr = json as? [Any] {
            for item in arr {
                if let found = walkForSubtitle(item, depth: depth + 1) {
                    return found
                }
            }
        }
        return nil
    }

    private static func isValidSubtitle(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
            && trimmed.count >= 3
            && trimmed.count <= 80
            && !trimmed.hasPrefix("http")
            && !trimmed.contains("@")
            && !trimmed.contains("{")
            && trimmed.filter({ $0.isLetter }).count >= 3
    }

    // HTML fallback patterns
    private static func parseSubtitleFromHTML(html: String) -> String? {
        let patterns = [
            // CSS class
            #"class="[^"]*product-header__subtitle[^"]*"[^>]*>([^<]{3,80})<"#,
            // JSON-LD alternativeHeadline
            #""alternativeHeadline"\s*:\s*"([^"]{3,80})""#,
            // schema subtitle
            #""subtitle"\s*:\s*"([^"]{3,80})""#,
        ]
        for pattern in patterns {
            if let match = regexCapture(pattern, in: html) {
                let clean = htmlDecode(match).trimmingCharacters(in: .whitespacesAndNewlines)
                if isValidSubtitle(clean) { return clean }
            }
        }
        return nil
    }

    // MARK: - iTunes Lookup
    private struct iTunesData {
        let subtitle: String
        let description: String
    }

    private static func fetchiTunesData(appId: Int, country: String) async -> iTunesData? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)&country=\(country)&entity=software") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first else { return nil }
            let subtitle    = first["subtitle"] as? String ?? ""
            let description = first["description"] as? String ?? ""
            print("[iTunes] subtitle: '\(subtitle.isEmpty ? "(empty)" : subtitle)'")
            return iTunesData(subtitle: subtitle, description: description)
        } catch { return nil }
    }

    // MARK: - GPT keyword extraction (no web_search, reads provided text)
    private struct ExtractedKeywords {
        let keywords: [String]
        let keywordsFromDescription: [String]
    }

    private static func extractKeywordsWithGPT(appName: String, subtitle: String, description: String) async -> ExtractedKeywords? {
        guard !Task.isCancelled else { return nil }
        guard !description.isEmpty || !subtitle.isEmpty else { return nil }

        let prompt = """
        Extract App Store search keywords from this app's information:

        App Name: \(appName)
        Subtitle: \(subtitle.isEmpty ? "(none)" : subtitle)
        Description:
        \(String(description.prefix(2000)))

        Return ONLY valid JSON:
        {
          "keywords": ["keyword1", "keyword2"],
          "keywords_from_description": ["phrase1", "phrase2"]
        }

        Rules:
        - keywords: 10-15 items from app name and subtitle. Lowercase, 1-4 words each.
        - keywords_from_description: 10-20 search phrases from description. Lowercase, specific terms users search.
        - No stopwords: "the","and","with","for","your","that"
        - No duplicates between arrays
        """

        let body: [String: Any] = [
            "model": "gpt-5-5",
            "stream": false,
            "reasoning": ["effort": "low"],
            "input": [["role": "user", "content": [["type": "input_text", "text": prompt]]]]
        ]

        for attempt in 1...3 {
            guard !Task.isCancelled else { return nil }
            if attempt > 1 {
                let delay = UInt64(attempt - 1) * 3_000_000_000
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return nil }
            }
            if let text = await callAPI(body: body, label: "Keywords #\(attempt)") {
                if let result = parseKeywordsJSON(from: text) { return result }
            }
        }
        // GPT failed — extract basic keywords from text without AI
        return extractKeywordsFallback(appName: appName, subtitle: subtitle, description: description)
    }

    // Simple keyword extraction fallback when GPT is unavailable
    private static func extractKeywordsFallback(appName: String, subtitle: String, description: String) -> ExtractedKeywords {
        let stopWords: Set<String> = ["the","and","for","with","your","that","this","from","have","are","app","you","not","all","can","get"]
        let text = "\(appName) \(subtitle)"
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
        let unique = Array(Set(words)).sorted()

        // Extract bigrams from description as description keywords
        let descWords = description.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 4 && !stopWords.contains($0) }
        let freq = descWords.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        let topDesc = freq.filter { $0.value >= 2 }.sorted { $0.value > $1.value }.prefix(15).map { $0.key }

        print("[Keywords] Fallback extraction: \(unique.count) kw, \(topDesc.count) desc")
        return ExtractedKeywords(keywords: Array(unique.prefix(12)), keywordsFromDescription: Array(topDesc))
    }

    // MARK: - Generate suggestions
    static func generateSuggestions(keywords: [String: (pop: Int, diff: Int, opp: Int)], competitorName: String) async -> String? {
        guard !Task.isCancelled else { return nil }

        let table = keywords.map { "- \"\($0.key)\" pop:\($0.value.pop) diff:\($0.value.diff) opp:\($0.value.opp)" }.joined(separator: "\n")

        let prompt = """
        You are an ASO expert. Competitor app: "\(competitorName)"
        Keywords: \(table)

        Generate 4 App Name + Subtitle + Keyword Field combinations.
        - App Name max 30 chars; Subtitle max 30 chars, different words from App Name
        - keyword_field: comma-separated max 100 chars, lowercase
        - Each targets a DIFFERENT keyword angle; all numeric fields are integers

        Return ONLY valid JSON:
        {"suggestions":[{"app_name":"...","subtitle":"...","keyword_field":"...","target_keywords":["kw"],"rationale":"...","avg_popularity":65,"avg_difficulty":35,"avg_opportunity":88}]}
        """

        let body: [String: Any] = [
            "model": "gpt-5-5",
            "stream": false,
            "reasoning": ["effort": "low"],
            "input": [["role": "user", "content": [["type": "input_text", "text": prompt]]]]
        ]

        for attempt in 1...2 {
            guard !Task.isCancelled else { return nil }
            if attempt == 2 { try? await Task.sleep(nanoseconds: 3_000_000_000) }
            if let text = await callAPI(body: body, label: "Generate #\(attempt)") { return text }
        }
        return nil
    }

    // MARK: - API caller
    static func callAPI(body: [String: Any], label: String) async -> String? {
        guard let reqURL = URL(string: endpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 45
        let session = URLSession(configuration: config)

        var request = URLRequest(url: reqURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, resp) = try await session.data(for: request)
            guard !Task.isCancelled else { return nil }
            if let http = resp as? HTTPURLResponse { print("[\(label)] HTTP \(http.statusCode)") }
            let rawStr = String(data: data, encoding: .utf8) ?? ""
            print("[\(label)] Raw: \(rawStr.prefix(300))")

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            if let code = json["code"] as? Int, code != 200 {
                print("[\(label)] Error \(code): \(json["msg"] ?? "")")
                return nil
            }

            if let output = json["output"] as? [[String: Any]] {
                for item in output {
                    guard item["type"] as? String == "message",
                          let content = item["content"] as? [[String: Any]] else { continue }
                    let text = content.filter { $0["type"] as? String == "output_text" }
                        .compactMap { $0["text"] as? String }.joined()
                    if !text.isEmpty { return text }
                }
            }
            print("[\(label)] No content — keys: \(json.keys.sorted().joined(separator:", "))")
            return nil
        } catch {
            if !(error is CancellationError) { print("[\(label)] Error: \(error.localizedDescription)") }
            return nil
        }
    }

    // MARK: - Parse keywords JSON
    private static func parseKeywordsJSON(from text: String) -> ExtractedKeywords? {
        let s = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        var depth = 0, start: String.Index? = nil, end: String.Index? = nil
        for idx in s.indices {
            switch s[idx] {
            case "{": if depth == 0 { start = idx }; depth += 1
            case "}": depth -= 1; if depth == 0, start != nil { end = idx }
            default: break
            }
            if end != nil { break }
        }
        guard let a = start, let b = end,
              let data = String(s[a...b]).data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let kw     = (raw["keywords"] as? [String] ?? []).map { $0.lowercased() }.filter { $0.count >= 2 }
        let kwDesc = (raw["keywords_from_description"] as? [String] ?? []).map { $0.lowercased() }.filter { $0.count >= 2 }
        print("[Keywords] OK — kw:\(kw.count) desc:\(kwDesc.count)")
        return ExtractedKeywords(keywords: kw, keywordsFromDescription: kwDesc)
    }

    // MARK: - Helpers
    private static func makeSlug(_ name: String) -> String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
            .joined()
    }

    private static func regexCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1 else { return nil }
        return ns.substring(with: match.range(at: 1))
    }

    private static func htmlDecode(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
         .replacingOccurrences(of: "&lt;", with: "<")
         .replacingOccurrences(of: "&gt;", with: ">")
         .replacingOccurrences(of: "&quot;", with: "\"")
         .replacingOccurrences(of: "&#39;", with: "'")
    }

    static func parseScrapeResult(from text: String) -> AppStoreScrapedData? { nil }
}
