import Foundation

actor iTunesService {
    static let shared = iTunesService()
    private let session = URLSession.shared

    func searchApps(term: String, country: String = "us", limit: Int = 10) async throws -> [AppResult] {
        var c = URLComponents(string: "https://itunes.apple.com/search")!
        c.queryItems = [
            .init(name: "term", value: term),
            .init(name: "entity", value: "software"),
            .init(name: "country", value: country),
            .init(name: "limit", value: "\(limit)")
        ]
        let (data, _) = try await session.data(from: c.url!)
        return try decode(data)
    }

    func searchKeyword(_ keyword: String, country: String = "us", limit: Int = 50) async throws -> [AppResult] {
        var c = URLComponents(string: "https://itunes.apple.com/search")!
        c.queryItems = [
            .init(name: "term", value: keyword),
            .init(name: "entity", value: "software"),
            .init(name: "country", value: country),
            .init(name: "limit", value: "\(limit)")
        ]
        let (data, _) = try await session.data(from: c.url!)
        return try decode(data)
    }

    func fetchRelatedKeywords(appName: String, country: String = "us") async -> [String] {
        var related: [String] = []
        let seeds = appName
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "&", with: " ")
            .split(separator: " ")
            .map { String($0).lowercased() }
            .filter { $0.count >= 4 && !["with","your","from","make","that","this"].contains($0) }

        for seed in seeds.prefix(3) {
            do {
                try? await Task.sleep(nanoseconds: 200_000_000)
                let apps = try await searchApps(term: seed, country: country, limit: 15)
                for app in apps {
                    related += app.trackName
                        .replacingOccurrences(of: ":", with: " ")
                        .replacingOccurrences(of: "&", with: " ")
                        .split(separator: " ")
                        .map { String($0).lowercased() }
                        .filter { $0.count >= 4 }
                }
            } catch { continue }
        }

        return related
            .reduce(into: [:]) { counts, word in counts[word, default: 0] += 1 }
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .map { $0.key }
            .filter { $0.count >= 3 && $0.count <= 25 && $0.first?.isLetter == true }
            .prefix(20).map { $0 }
    }

    nonisolated private func decode(_ data: Data) throws -> [AppResult] {
        try JSONDecoder().decode(iTunesSearchResponse.self, from: data).results
    }
}
