import Foundation

struct NameGenerator {

    static func generateWithAI(keywords: [Keyword], competitorName: String) async -> [AppNameSuggestion] {
        guard !keywords.isEmpty else { return [] }

        let top = Array(keywords.sorted { $0.opportunity > $1.opportunity }.prefix(40))

        // Build keyword dict for GPTService
        var kwDict: [String: (pop: Int, diff: Int, opp: Int)] = [:]
        for kw in top {
            kwDict[kw.term] = (kw.popularity, kw.difficulty, kw.opportunity)
        }

        guard let rawText = await GPTService.generateSuggestions(
            keywords: kwDict,
            competitorName: competitorName
        ) else {
            print("[NameGenerator] GPT-5.5 failed, using fallback")
            return fallback(from: keywords)
        }

        return parseSuggestions(from: rawText) ?? fallback(from: keywords)
    }

    private static func parseSuggestions(from text: String) -> [AppNameSuggestion]? {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find outermost { }
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
              let data = String(stripped[s...e]).data(using: .utf8) else { return nil }

        struct Wrapper: Codable {
            let suggestions: [Item]
        }
        struct Item: Codable {
            let appName: String
            let subtitle: String
            let keywordField: String
            let targetKeywords: [String]
            let rationale: String
            let avgPopularity: Int
            let avgDifficulty: Int
            let avgOpportunity: Int
            enum CodingKeys: String, CodingKey {
                case appName = "app_name"
                case subtitle
                case keywordField = "keyword_field"
                case targetKeywords = "target_keywords"
                case rationale
                case avgPopularity = "avg_popularity"
                case avgDifficulty = "avg_difficulty"
                case avgOpportunity = "avg_opportunity"
            }
        }

        do {
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            print("[NameGenerator] GPT-5.5 success: \(wrapper.suggestions.count) suggestions")
            return wrapper.suggestions.map {
                AppNameSuggestion(
                    appName: String($0.appName.prefix(30)),
                    subtitle: String($0.subtitle.prefix(30)),
                    keywordField: enforceLimit($0.keywordField),
                    keywords: $0.targetKeywords,
                    avgPopularity: $0.avgPopularity,
                    avgDifficulty: $0.avgDifficulty,
                    avgOpportunity: $0.avgOpportunity,
                    rationale: $0.rationale
                )
            }
        } catch {
            print("[NameGenerator] Decode error: \(error)")
            return nil
        }
    }

    private static func enforceLimit(_ field: String) -> String {
        let clean = field.replacingOccurrences(of: ", ", with: ",").lowercased()
        guard clean.count > 100 else { return clean }
        let t = String(clean.prefix(100))
        return t.lastIndex(of: ",").map { String(t[..<$0]) } ?? t
    }

    // MARK: - Algorithmic fallback

    static func fallback(from keywords: [Keyword]) -> [AppNameSuggestion] {
        let pool = keywords
            .filter { $0.opportunity > 25 && $0.difficulty < 70 && $0.popularity > 20 }
            .filter { isClean($0.term) }
            .sorted { $0.opportunity > $1.opportunity }
        guard pool.count >= 2 else { return [] }

        var suggestions: [AppNameSuggestion] = []
        var used: Set<String> = []

        for i in 0..<min(pool.count, 10) {
            let primary = pool[i]
            guard isStandalone(primary.term) else { continue }
            guard let secondary = pool.first(where: {
                $0.term != primary.term &&
                !$0.term.contains(primary.term) &&
                !primary.term.contains($0.term) &&
                isStandalone($0.term)
            }) else { continue }

            let name = cap(primary.term)
            let sub  = buildSub(secondary.term)
            guard name.count <= 30, sub.count <= 30 else { continue }
            let key = "\(name)|\(sub)"
            guard !used.contains(key) else { continue }
            used.insert(key)

            let usedWords = Set((name + " " + sub).lowercased().split(separator: " ").map(String.init))
            let kwField = buildField(from: pool, excluding: usedWords)

            suggestions.append(AppNameSuggestion(
                appName: name, subtitle: sub, keywordField: kwField,
                keywords: [primary.term, secondary.term],
                avgPopularity: (primary.popularity + secondary.popularity) / 2,
                avgDifficulty: (primary.difficulty + secondary.difficulty) / 2,
                avgOpportunity: (primary.opportunity + secondary.opportunity) / 2,
                rationale: "Pop \(primary.popularity) · opp \(primary.opportunity)"
            ))
            if suggestions.count >= 4 { break }
        }
        return suggestions
    }

    private static func buildField(from pool: [Keyword], excluding used: Set<String>) -> String {
        var result = ""
        for kw in pool {
            let words = Set(kw.term.split(separator: " ").map(String.init))
            guard words.isDisjoint(with: used) else { continue }
            let candidate = result.isEmpty ? kw.term : result + "," + kw.term
            guard candidate.count <= 100 else { break }
            result = candidate
        }
        return result
    }

    private static func isClean(_ t: String) -> Bool {
        guard let f = t.first, f.isLetter else { return false }
        return !t.hasPrefix("&") && !t.hasSuffix("&")
    }
    private static func isStandalone(_ t: String) -> Bool {
        let generic: Set<String> = ["app","timer","tracker","free","pro","video","maker"]
        let words = t.lowercased().split(separator:" ").map(String.init)
        if words.count == 1 && generic.contains(words[0]) { return false }
        return isClean(t)
    }
    private static func cap(_ t: String) -> String {
        t.split(separator:" ").map { $0.prefix(1).uppercased()+$0.dropFirst().lowercased() }.joined(separator:" ")
    }
    private static func buildSub(_ s: String) -> String {
        let c = cap(s)
        return ["\(c) & More","Your \(c) Tool","\(c) Made Easy"].first { $0.count <= 30 } ?? c
    }
}
