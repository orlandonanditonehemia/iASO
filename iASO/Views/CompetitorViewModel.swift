import Foundation
import Observation

@Observable
@MainActor
class CompetitorViewModel {
    var competitor: AppResult?
    var keywords: [Keyword] = []
    var suggestions: [AppNameSuggestion] = []
    var isAnalyzing: Bool = false
    var isGenerating: Bool = false
    var isAILoading: Bool = false
    var isAddingKeyword: Bool = false
    var country: String = "us"
    var scoringProgress: String = ""
    var scrapeError: Bool = false
    var scrapeAttempt: Int = 0
    var useGPT: Bool = false

    // Cached metadata — reused when only country changes
    private var cachedScrapedData: AppStoreScrapedData? = nil
    private var cachedCandidates: [String] = []
    private var cachedAppId: Int? = nil

    private var currentTask: Task<Void, Never>?

    func analyze(app: AppResult) {
        currentTask?.cancel()
        currentTask = nil
        competitor = app
        keywords = []
        suggestions = []
        scoringProgress = ""
        scrapeError = false
        scrapeAttempt = 0
        isAnalyzing = true
        isAILoading = false

        // Clear cache when switching to a different app
        if cachedAppId != app.id {
            cachedScrapedData = nil
            cachedCandidates = []
            cachedAppId = app.id
        }

        currentTask = Task { await runAnalysis(for: app, forceRescrape: false) }
    }

    func retryAnalysis() {
        guard let app = competitor else { return }
        // Force rescrape on explicit retry
        cachedScrapedData = nil
        cachedCandidates = []
        analyze(app: app)
    }

    func cancelAnalysis() {
        currentTask?.cancel()
        currentTask = nil
        isAnalyzing = false
        isAILoading = false
        scrapeError = false
        scrapeAttempt = 0
        scoringProgress = ""
    }

    func changeCountry(_ newCountry: String, app: AppResult) {
        currentTask?.cancel()
        currentTask = nil
        country = newCountry
        keywords = []
        suggestions = []
        scoringProgress = ""
        scrapeError = false
        isAnalyzing = true
        isAILoading = false

        currentTask = Task { await runAnalysis(for: app, forceRescrape: false) }
    }

    func generateSuggestions() async {
        guard !keywords.isEmpty else { return }
        isGenerating = true
        let name = competitor?.trackName ?? "competitor app"
        let result = await NameGenerator.generateWithAI(keywords: keywords, competitorName: name)
        guard !Task.isCancelled else { isGenerating = false; return }
        suggestions = result
        isGenerating = false
    }

    func addKeyword(_ term: String) async {
        let clean = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, !keywords.contains(where: { $0.term == clean }) else { return }
        isAddingKeyword = true
        if let kw = await scoreKeyword(clean, for: competitor ?? .placeholder) {
            insertSorted(kw)
        }
        isAddingKeyword = false
    }

    // MARK: - Private

    private func runAnalysis(for app: AppResult, forceRescrape: Bool) async {
        defer {
            if !Task.isCancelled {
                isAnalyzing = false
                isAILoading = false
                scoringProgress = ""
            }
        }

        var scraped: AppStoreScrapedData?
        var candidates: [String]

        // Use cache if available and not forced rescrape
        if !forceRescrape, let cached = cachedScrapedData, !cachedCandidates.isEmpty {
            print("[ViewModel] Using cached metadata for '\(app.trackName)' — skipping scrape")
            scraped = cached
            candidates = cachedCandidates
        } else {
            // Subtitle always via URLSession (fast, no GPT)
            // GPT keyword extraction is optional — controlled by useGPT toggle
            isAILoading = useGPT

            scraped = await GPTService.scrapeAppStore(
                appId: app.id,
                appName: app.trackName,
                country: country,
                extractKeywords: useGPT
            )
            isAILoading = false

            if scraped == nil {
                scrapeError = true
                isAnalyzing = false
                return
            }

            if !useGPT {
                print("[ViewModel] GPT disabled — subtitle: '\(scraped?.subtitle ?? "none")', keywords from local only")
            }

            guard !Task.isCancelled else { return }

            // STEP 2: Build candidates (also cached)
            var built: [String] = []
            built += scraped?.keywords ?? []
            built += scraped?.keywordsFromDescription ?? []

            guard !Task.isCancelled else { return }

            var enrichedForExtract = app
            enrichedForExtract.subtitle = scraped?.subtitle.isEmpty == false ? scraped?.subtitle : nil
            built += await KeywordExtractor.extract(from: enrichedForExtract)

            guard !Task.isCancelled else { return }
            built += await iTunesService.shared.fetchRelatedKeywords(appName: app.trackName, country: country)

            guard !Task.isCancelled else { return }

            candidates = deduplicatePreservingOrder(built).filter { isValid($0) }

            // Cache for next country switch
            cachedScrapedData = scraped
            cachedCandidates  = candidates
            print("[ViewModel] Metadata cached — \(candidates.count) candidates")
        }

        // Apply scraped metadata to competitor
        var enriched = app
        enriched.subtitle = scraped?.subtitle.isEmpty == false ? scraped?.subtitle : nil
        enriched.metadataKeywords = scraped?.keywords ?? []
        competitor = enriched
        print("[ViewModel] Subtitle: '\(scraped?.subtitle ?? "")'")
        print("[ViewModel] Scoring \(candidates.count) candidates for country: \(country)")

        // STEP 3: Score keywords in parallel (always re-run for new country)
        scoringProgress = "0 / \(candidates.count) scored"
        var count = 0

        await withTaskGroup(of: Keyword?.self) { group in
            let semaphore = AsyncSemaphore(limit: 3)
            for term in candidates {
                guard !Task.isCancelled else { break }
                await semaphore.wait()
                group.addTask {
                    defer { Task { await semaphore.signal() } }
                    guard !Task.isCancelled else { return nil }
                    return await self.scoreKeyword(term, for: app)
                }
            }
            for await result in group {
                guard !Task.isCancelled else { continue }
                if let kw = result { insertSorted(kw) }
                count += 1
                scoringProgress = "\(count) / \(candidates.count) scored"
            }
        }
    }

    private func insertSorted(_ kw: Keyword) {
        let idx = keywords.firstIndex { existing in
            if kw.position != nil && existing.position == nil { return true }
            if kw.position == nil && existing.position != nil { return false }
            if let kwPos = kw.position, let exPos = existing.position { return kwPos < exPos }
            return kw.opportunity > existing.opportunity
        } ?? keywords.endIndex
        keywords.insert(kw, at: idx)
    }

    private func scoreKeyword(_ term: String, for app: AppResult) async -> Keyword? {
        guard !Task.isCancelled else { return nil }
        do {
            let apps = try await iTunesService.shared.searchKeyword(term, country: country)
            guard !apps.isEmpty, !Task.isCancelled else { return nil }
            let pop  = ScoringEngine.popularity(for: apps, keyword: term)
            let diff = ScoringEngine.difficulty(for: apps, keyword: term)
            let opp  = ScoringEngine.opportunity(popularity: pop, difficulty: diff)
            let cls  = ScoringEngine.classify(popularity: pop, difficulty: diff)
            let pos  = apps.firstIndex { $0.id == app.id }.map { $0 + 1 }
            return Keyword(term: term, popularity: pop, difficulty: diff,
                          opportunity: opp, classification: cls,
                          position: pos, topApps: Array(apps.prefix(25)))
        } catch { return nil }
    }

    private func deduplicatePreservingOrder(_ list: [String]) -> [String] {
        var seen = Set<String>()
        return list.filter { seen.insert($0).inserted }
    }

    private func isValid(_ term: String) -> Bool {
        guard term.count >= 3, term.count <= 30 else { return false }
        guard term.first?.isLetter == true else { return false }
        guard !term.hasPrefix("&"), Int(term) == nil else { return false }
        let stop: Set<String> = [
            "the","and","for","with","app","you","are","this","that",
            "have","from","not","all","can","get","inc","llc","ltd",
            "com","ios","mac","just","also","use","make","more","your"
        ]
        return !stop.contains(term.lowercased())
    }
}

// MARK: - Async semaphore

actor AsyncSemaphore {
    private var limit: Int
    private var current = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    init(limit: Int) { self.limit = limit }
    func wait() async {
        if current < limit { current += 1 }
        else { await withCheckedContinuation { waiters.append($0) } }
    }
    func signal() {
        if let next = waiters.first { waiters.removeFirst(); next.resume() }
        else { current = max(0, current - 1) }
    }
}

extension AppResult {
    static let placeholder = AppResult(
        id: 0, trackName: "", artistName: "", artworkUrl60: nil, artworkUrl100: nil,
        primaryGenreName: nil, averageUserRating: nil, userRatingCount: nil,
        currentVersionReleaseDate: nil, releaseDate: nil, description: nil,
        version: nil, price: nil, formattedPrice: nil, minimumOsVersion: nil,
        fileSizeBytes: nil
    )
}
