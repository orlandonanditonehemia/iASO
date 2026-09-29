//
//  KeywordExtractor.swift
//  iASO
//
//  Created by profitfirst on 03/05/26.
//

import Foundation
import NaturalLanguage

struct KeywordExtractor {

    static func extract(from app: AppResult) async -> [String] {
        var candidates: [String] = []

        // 1. Tokenize app name (cleaned)
        let cleanName = cleanText(app.trackName)
        candidates += tokenize(cleanName)
        candidates += bigrams(from: cleanName)

        // 2. From description — first 200 chars
        if let desc = app.description {
            let firstPart = String(desc.prefix(200))
            candidates += tokenize(cleanText(firstPart)).prefix(15).map { $0 }
        }

        // Deduplicate + filter
        return Array(Set(candidates))
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { isValidKeyword($0) }
            .prefix(50)
            .map { $0 }
    }

    static func cleanText(_ text: String) -> String {
        var result = text
        for char in ["&", ":", "-", "+", "(", ")"] {
            result = result.replacingOccurrences(of: char, with: " ")
        }
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isValidKeyword(_ term: String) -> Bool {
        guard term.count >= 3, term.count <= 30 else { return false }
        guard term.first?.isLetter == true else { return false }
        guard Int(term) == nil else { return false }
        return !stopWords.contains(term)
    }

    private static func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }

    private static func bigrams(from text: String) -> [String] {
        let words = text.split(separator: " ")
            .map { String($0) }
            .filter { $0.count >= 3 }
        guard words.count >= 2 else { return [] }
        return zip(words, words.dropFirst()).map { "\($0) \($1)" }
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "with", "app", "your", "you", "are",
        "this", "that", "have", "from", "not", "all", "can", "get",
        "our", "will", "one", "more", "new", "best", "free", "now",
        "use", "make", "just", "also", "very", "its", "has", "was",
        "but", "any", "inc", "llc", "ltd", "com", "ios", "mac"
    ]
}
