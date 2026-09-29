import Foundation

struct Keyword: Identifiable {
    let id = UUID()
    let term: String
    var popularity: Int
    var difficulty: Int
    var opportunity: Int
    var classification: ScoringEngine.KeywordClass
    var position: Int?
    var topApps: [AppResult]
}
