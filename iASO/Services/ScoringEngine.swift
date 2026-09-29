import Foundation

// MARK: - ScoringEngine
// Exact Swift port of RespectASO:
//   aso/scoring.py  → opportunity(), classify()
//   aso/services.py → PopularityEstimator.estimate(), DifficultyCalculator.calculate()

struct ScoringEngine {

    // MARK: - Opportunity (exact port of scoring.py calc_opportunity)
    // _POP_TO_SEARCHES lookup table
    private static let popToSearches: [(Int, Double)] = [
        (5, 1), (10, 3), (15, 5), (20, 10), (25, 20), (30, 35),
        (35, 55), (40, 90), (45, 140), (50, 200), (55, 290), (60, 400),
        (65, 550), (70, 750), (75, 1_100), (80, 2_000), (85, 4_000),
        (90, 8_000), (95, 16_000), (100, 32_000)
    ]
    private static let maxSearches: Double = 32_000

    private static func popToSearchesValue(_ popularity: Int) -> Double {
        guard popularity > 0 else { return 0 }
        let pts = popToSearches
        if popularity <= pts.first!.0 {
            return pts.first!.1 * (Double(popularity) / Double(pts.first!.0))
        }
        if popularity >= pts.last!.0 { return pts.last!.1 }
        for i in 1..<pts.count {
            let (p0, s0) = pts[i-1]; let (p1, s1) = pts[i]
            if popularity <= p1 {
                let ratio = Double(popularity - p0) / Double(p1 - p0)
                return s0 + ratio * (s1 - s0)
            }
        }
        return pts.last!.1
    }

    static func opportunity(popularity: Int, difficulty: Int) -> Int {
        guard popularity > 0 else { return 0 }
        let searches = popToSearchesValue(popularity)
        guard searches > 0 else { return 0 }
        let volume = log10(1 + searches) / log10(1 + maxSearches)
        let gate   = 1.0 - pow(Double(difficulty) / 100.0, 2)
        let raw    = volume * gate * 100.0
        return max(0, min(100, Int(raw)))
    }

    // MARK: - Classification (exact port of scoring.py classify_keyword)
    static func classify(popularity: Int, difficulty: Int) -> KeywordClass {
        let opp = opportunity(popularity: popularity, difficulty: difficulty)
        if popularity >= 40 && difficulty <= 40          { return .sweetSpot }
        if popularity >= 25 && popularity < 40 && difficulty <= 30 && opp >= 30 { return .hiddenGem }
        if popularity < 15                               { return .lowVolume }
        if difficulty >= 65                              { return .highCompetition }
        if opp >= 55                                     { return .goodTarget }
        if opp <= 25                                     { return .avoid }
        return .moderate
    }

    enum KeywordClass: String {
        case sweetSpot       = "Sweet Spot"
        case hiddenGem       = "Hidden Gem"
        case lowVolume       = "Low Volume"
        case highCompetition = "High Competition"
        case goodTarget      = "Good Target"
        case avoid           = "Avoid"
        case moderate        = "Moderate"
    }

    // MARK: - Popularity (exact port of services.py PopularityEstimator.estimate)
    static func popularity(for apps: [AppResult], keyword: String) -> Int {
        guard !apps.isEmpty else { return 5 }

        let n = apps.count
        let kwLower = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        let wordCount = kwLower.isEmpty ? 1 : kwLower.split(separator: " ").count

        // Signal 1: Result count (0–25 pts) — n * 2.5
        let resultScore = min(25.0, Double(n) * 2.5)

        // Signal 2: Leader strength (0–30 pts)
        // Uses top half only, smooth log interpolation across bands
        let topHalf = Array(apps.prefix(max(n / 2, 1)))
        let maxReviews = topHalf.compactMap { $0.userRatingCount }.max() ?? 0
        let leaderScore: Double
        if maxReviews <= 0 {
            leaderScore = 0
        } else if maxReviews >= 1_000_000 {
            leaderScore = 30
        } else {
            let leaderBands: [(Int, Double)] = [
                (10, 1), (100, 5), (1_000, 10), (10_000, 17), (100_000, 24), (1_000_000, 30)
            ]
            var ls = 0.0
            for i in 0..<leaderBands.count {
                let (threshold, score) = leaderBands[i]
                if maxReviews < threshold {
                    if i == 0 {
                        ls = (Double(maxReviews) / Double(threshold)) * score
                    } else {
                        let (prevT, prevS) = leaderBands[i-1]
                        let ratio = log(Double(maxReviews) / Double(prevT)) / log(Double(threshold) / Double(prevT))
                        ls = prevS + ratio * (score - prevS)
                    }
                    break
                }
                if i == leaderBands.count - 1 { ls = 30 }
            }
            leaderScore = ls
        }

        // Signal 3: Title match density (0–20 pts)
        var titleMatches = 0
        var exactPhraseMatches = 0
        var relevanceSum = 0.0
        for app in apps {
            let ev = keywordTitleEvidence(kwLower, title: app.trackName, genre: app.primaryGenreName ?? "")
            relevanceSum += ev.evidence
            if ev.exactPhrase { titleMatches += 1; exactPhraseMatches += 1 }
            else if ev.allWords { titleMatches += 1 }
        }
        var titleScore = min(20.0, (Double(titleMatches) / Double(n)) * 40.0)

        // Signal 4: Market depth — median reviews (0–10 pts)
        let sortedCounts = apps.compactMap { $0.userRatingCount }.sorted()
        let median: Double
        if sortedCounts.isEmpty {
            median = 0
        } else if sortedCounts.count % 2 == 1 {
            median = Double(sortedCounts[sortedCounts.count / 2])
        } else {
            median = Double(sortedCounts[sortedCounts.count/2 - 1] + sortedCounts[sortedCounts.count/2]) / 2.0
        }
        let depthScore: Double
        if median <= 0 {
            depthScore = 0
        } else if median >= 50_000 {
            depthScore = 10
        } else {
            let depthBands: [(Double, Double)] = [
                (10, 0.5), (100, 3), (1_000, 5), (10_000, 8), (50_000, 10)
            ]
            var ds = 0.0
            for i in 0..<depthBands.count {
                let (threshold, score) = depthBands[i]
                if median < threshold {
                    if i == 0 {
                        ds = (median / threshold) * score
                    } else {
                        let (prevT, prevS) = depthBands[i-1]
                        let ratio = log(median / prevT) / log(threshold / prevT)
                        ds = prevS + ratio * (score - prevS)
                    }
                    break
                }
                if i == depthBands.count - 1 { ds = 10 }
            }
            depthScore = ds
        }

        // Signal 5: Specificity penalty (-5 to -28 pts)
        let spPoints: [(Int, Double)] = [(1,0),(2,-3),(3,-8),(4,-15),(5,-22),(6,-28)]
        let specificityPenalty: Double
        if wordCount <= 1 { specificityPenalty = 0 }
        else if wordCount >= 6 { specificityPenalty = -28 }
        else {
            var sp = -28.0
            for i in 0..<spPoints.count-1 {
                let (loW, loV) = spPoints[i]
                let (hiW, hiV) = spPoints[i+1]
                if loW <= wordCount && wordCount <= hiW {
                    let t = Double(wordCount - loW) / Double(hiW - loW)
                    sp = loV + t * (hiV - loV)
                    break
                }
            }
            specificityPenalty = sp
        }

        // Signal 6: Exact phrase match bonus (0–15 pts)
        var exactBonus = min(15.0, (Double(exactPhraseMatches) / Double(n)) * 50.0)

        // Small sample dampening (reaches full strength at n=10)
        let sampleDampening = min(1.0, Double(n) / 10.0)
        titleScore *= sampleDampening
        exactBonus *= sampleDampening

        // Backfill-aware dampening
        let relevanceRatio = relevanceSum / Double(max(n, 1))
        let relevance = max(0.3, min(1.0, relevanceRatio * 2.6))
        let finalResultScore = resultScore * relevance
        let finalLeaderScore = leaderScore * relevance
        let finalDepthScore  = depthScore * relevance

        let total = Int(finalResultScore + finalLeaderScore + titleScore + finalDepthScore + specificityPenalty + exactBonus)
        return max(5, min(100, total))
    }

    // MARK: - Difficulty (exact port of services.py DifficultyCalculator.calculate + _compute_raw_difficulty)
    static func difficulty(for apps: [AppResult], keyword: String) -> Int {
        guard !apps.isEmpty else { return 0 }

        let n = apps.count
        let kwLower = keyword.lowercased().trimmingCharacters(in: .whitespaces)

        // --- Sub-scores ---

        // Rating Volume (30%) — log-scale median
        let ratingCounts = apps.compactMap { $0.userRatingCount }
        let sortedRatings = ratingCounts.sorted()
        let medianRatings: Double
        if sortedRatings.isEmpty { medianRatings = 0 }
        else if sortedRatings.count % 2 == 1 { medianRatings = Double(sortedRatings[sortedRatings.count/2]) }
        else { medianRatings = Double(sortedRatings[sortedRatings.count/2-1] + sortedRatings[sortedRatings.count/2]) / 2.0 }
        let ratingVolume = ratingVolumeScore(medianRatings)

        // Review Velocity (10%)
        let reviewVelocity = reviewVelocityScore(apps)

        // Dominant Players (20%) — continuous log dominance, weighted top-half
        let logCeiling = log10(10_000_000.0)
        let topHalfSize = max(n / 2, 1)
        var dominanceTotal = 0.0
        for (i, app) in apps.enumerated() {
            let r = app.userRatingCount ?? 0
            guard r > 0 else { continue }
            let appDominance = min(1.0, log10(Double(max(r, 1))) / logCeiling)
            let weight = i < topHalfSize ? 2.0 : 1.0
            dominanceTotal += appDominance * weight
        }
        let weightSum = 2.0 * Double(topHalfSize) + 1.0 * Double(max(n - topHalfSize, 0))
        var dominantPlayers = min(100.0, (dominanceTotal / max(weightSum, 1)) * 100.0)

        // Rating Quality (10%) — review-weighted avg star rating
        var weightedStarSum = 0.0; var weightTotal = 0.0
        for app in apps {
            let rating = app.averageUserRating ?? 0
            let reviews = app.userRatingCount ?? 0
            if rating > 0 && reviews > 0 {
                let w = log(1 + Double(reviews))  // log1p equivalent
                weightedStarSum += rating * w
                weightTotal += w
            }
        }
        let avgQuality = weightTotal > 0 ? weightedStarSum / weightTotal : 0
        var ratingQuality = ratingQualityScore(avgQuality)

        // Market Age (10%)
        var marketAge = marketAgeScore(apps)

        // Publisher Diversity (10%)
        let uniquePubs = Set(apps.compactMap { $0.artistName.isEmpty ? nil : $0.artistName.lowercased() }).count
        var publisherDiversity = min(100.0, (Double(uniquePubs) / Double(max(n, 1))) * 100.0)

        // Title Relevance (10%)
        var titleMatchCount = 0
        var relevanceSum = 0.0
        for app in apps {
            let ev = keywordTitleEvidence(kwLower, title: app.trackName, genre: app.primaryGenreName ?? "")
            relevanceSum += ev.evidence
            if ev.exactPhrase || ev.allWords { titleMatchCount += 1 }
        }
        var titleRelevance = min(100.0, (Double(titleMatchCount) / Double(max(n, 1))) * 100.0)

        // Small sample dampening
        let sampleDampening = min(1.0, Double(n) / 10.0)
        publisherDiversity *= sampleDampening
        titleRelevance     *= sampleDampening
        dominantPlayers    *= sampleDampening
        ratingQuality      *= sampleDampening

        // Backfill-aware dampening
        let relevanceRatio = relevanceSum / Double(max(n, 1))
        let relevanceFactor = max(0.3, min(1.0, relevanceRatio * 2.6))
        publisherDiversity *= relevanceFactor
        ratingQuality      *= relevanceFactor
        marketAge          *= relevanceFactor

        var total = Int(
            ratingVolume   * 0.30 +
            reviewVelocity * 0.10 +
            dominantPlayers * 0.20 +
            ratingQuality  * 0.10 +
            marketAge      * 0.10 +
            publisherDiversity * 0.10 +
            titleRelevance * 0.10
        )
        total = max(1, min(100, total))

        // --- Post-processing overrides ---
        let leaderReviews = apps.first?.userRatingCount ?? 0
        let matchRatio = Double(titleMatchCount) / Double(max(n, 1))

        // Small result set cap
        let smallCaps: [Int: Int] = [1: 10, 2: 20, 3: 31, 4: 40]
        if let cap = smallCaps[n], total > cap {
            total = cap
        } else if n >= 2 && !kwLower.isEmpty {
            // Weak leader cap
            if leaderReviews < 1_000 {
                let leaderCap = Int(15.0 + 35.0 * log10(Double(leaderReviews) + 1) / log10(1001.0))
                if total > leaderCap {
                    if matchRatio > 0.2 {
                        total = Int(Double(leaderCap) + Double(total - leaderCap) * matchRatio)
                    } else {
                        total = leaderCap
                    }
                }
            }

            // Backfill discount
            if matchRatio < 0.2 && leaderReviews < 1_000 {
                let ratioFactor = min(1.0, 0.6 + 2.0 * matchRatio)
                let leaderFactor = log10(Double(leaderReviews) + 1) / log10(1001.0)
                let discount = max(0.6, min(1.0, ratioFactor + (1.0 - ratioFactor) * leaderFactor))
                let discounted = max(1, Int(Double(total) * discount))
                if discounted < total { total = discounted }
            }
        }

        return max(1, min(100, total))
    }

    // MARK: - Helper sub-score functions (exact ports)

    private static func ratingVolumeScore(_ median: Double) -> Double {
        if median <= 0 { return 0 }
        if median >= 100_000 { return 100 }
        let bands: [(Double, Double)] = [
            (50, 5), (200, 15), (500, 30), (2_000, 50),
            (5_000, 65), (10_000, 78), (25_000, 88), (100_000, 95)
        ]
        for i in 0..<bands.count {
            let (threshold, score) = bands[i]
            if median < threshold {
                if i == 0 { return (median / threshold) * score }
                let (prevT, prevS) = bands[i-1]
                let ratio = log(median / prevT) / log(threshold / prevT)
                return prevS + ratio * (score - prevS)
            }
        }
        return 100
    }

    private static func reviewVelocityScore(_ apps: [AppResult]) -> Double {
        let now = Date()
        let isoFmt = ISO8601DateFormatter()
        var velocities: [Double] = []
        for app in apps {
            let reviews = app.userRatingCount ?? 0
            guard reviews > 0, let dateStr = app.releaseDate,
                  let released = isoFmt.date(from: dateStr) else { continue }
            let ageYears = max(0.5, now.timeIntervalSince(released) / (365.25 * 24 * 3600))
            velocities.append(Double(reviews) / ageYears)
        }
        if velocities.isEmpty { return 50 }
        velocities.sort()
        let vn = velocities.count
        let medianVel = vn % 2 == 1 ? velocities[vn/2] : (velocities[vn/2-1] + velocities[vn/2]) / 2.0
        if medianVel <= 0 { return 0 }
        if medianVel >= 50_000 { return 100 }
        let bands: [(Double, Double)] = [
            (10, 5), (50, 15), (200, 30), (1_000, 50), (5_000, 70), (20_000, 85), (50_000, 95)
        ]
        for i in 0..<bands.count {
            let (threshold, score) = bands[i]
            if medianVel < threshold {
                if i == 0 { return (medianVel / threshold) * score }
                let (prevT, prevS) = bands[i-1]
                let ratio = log(medianVel / prevT) / log(threshold / prevT)
                return prevS + ratio * (score - prevS)
            }
        }
        return 100
    }

    private static func ratingQualityScore(_ avgQuality: Double) -> Double {
        if avgQuality <= 0 { return 0 }
        if avgQuality >= 5.0 { return 100 }
        let bands: [(Double, Double)] = [
            (0.0, 0), (3.0, 20), (3.5, 35), (4.0, 50), (4.3, 70), (4.5, 85), (5.0, 100)
        ]
        for i in 1..<bands.count {
            let (threshold, score) = bands[i]
            if avgQuality < threshold {
                let (prevT, prevS) = bands[i-1]
                let ratio = (avgQuality - prevT) / (threshold - prevT)
                return prevS + ratio * (score - prevS)
            }
        }
        return 100
    }

    private static func marketAgeScore(_ apps: [AppResult]) -> Double {
        let now = Date()
        let isoFmt = ISO8601DateFormatter()
        var ages: [Double] = []
        for app in apps {
            guard let dateStr = app.releaseDate ?? app.currentVersionReleaseDate,
                  let released = isoFmt.date(from: dateStr) else { continue }
            ages.append(now.timeIntervalSince(released) / (365.25 * 24 * 3600))
        }
        if ages.isEmpty { return 50 }
        let avgAge = ages.reduce(0, +) / Double(ages.count)
        if avgAge <= 0 { return 0 }
        if avgAge >= 10 { return 100 }
        let bands: [(Double, Double)] = [
            (0.5, 10), (1.0, 20), (2.0, 35), (3.0, 50), (5.0, 70), (8.0, 85), (10.0, 100)
        ]
        for i in 0..<bands.count {
            let (threshold, score) = bands[i]
            if avgAge < threshold {
                if i == 0 { return (avgAge / threshold) * score }
                let (prevT, prevS) = bands[i-1]
                let ratio = (avgAge - prevT) / (threshold - prevT)
                return prevS + ratio * (score - prevS)
            }
        }
        return 100
    }

    // MARK: - Keyword title evidence (port of _keyword_title_evidence)
    private struct TitleEvidence {
        let exactPhrase: Bool
        let allWords: Bool
        let evidence: Double
    }

    private static func keywordTitleEvidence(_ keyword: String, title: String, genre: String) -> TitleEvidence {
        let kw = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        let titleLower = title.lowercased()
        let kwTokens = tokenize(kw)
        let titleTokens = tokenize(titleLower)
        let kwSet = Set(kwTokens)
        let titleSet = Set(titleTokens)

        guard !kwSet.isEmpty, !titleSet.isEmpty else {
            return TitleEvidence(exactPhrase: false, allWords: false, evidence: 0)
        }

        var exactPhrase = !kw.isEmpty && titleLower.contains(kw)
        var allWords = kwSet.allSatisfy { titleSet.contains($0) }
        let overlap = Double(kwSet.intersection(titleSet).count) / Double(kwSet.count)

        // Finance ambiguity guard (simplified — not tracking genre deeply)
        let financeIntentTokens: Set<String> = ["option","options","trading","trade","stock","stocks","call","put","signal","signals","invest","investing"]
        let hasFinanceIntent = !kwSet.intersection(financeIntentTokens).isEmpty
        let financeContextTokens: Set<String> = ["finance","financial","stock","stocks","trading","trade","portfolio","broker","invest","investing","market","markets","futures","forex","etf"]
        let hasFinanceContext = !titleSet.intersection(financeContextTokens).isEmpty || genre.lowercased().contains("finance")
        if hasFinanceIntent && !hasFinanceContext && (exactPhrase || allWords) {
            exactPhrase = false; allWords = false
        }

        let strongScore: Double
        if exactPhrase { strongScore = 1.0 }
        else if allWords {
            // Proximity bonus
            var proximity = 0.0
            if kwTokens.count > 1 {
                var positions: [Int] = []
                for token in kwTokens {
                    if let idx = titleTokens.firstIndex(of: token) { positions.append(idx) }
                }
                if !positions.isEmpty {
                    let span = max(1, positions.max()! - positions.min()! + 1)
                    proximity = min(1.0, Double(kwTokens.count) / Double(span))
                }
            }
            strongScore = 0.85 + 0.15 * proximity
        } else { strongScore = 0.0 }

        let partialScore = (!exactPhrase && !allWords && overlap > 0) ? min(0.5, overlap * 0.5) : 0.0
        let evidence = max(strongScore, partialScore)

        return TitleEvidence(exactPhrase: exactPhrase, allWords: allWords, evidence: evidence)
    }

    // Tokenize (port of _tokenize — alphanumeric, normalize plurals)
    private static let tokenNormalization: [String: String] = [
        "options": "option", "stocks": "stock", "signals": "signal", "markets": "market"
    ]
    private static func tokenize(_ text: String) -> [String] {
        let raw = text.unicodeScalars.split { !CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).contains($0) }
            .map { String($0).lowercased() }
            .filter { !$0.isEmpty && $0 != "_" }
        return raw.map { tokenNormalization[$0] ?? $0 }
    }
}
