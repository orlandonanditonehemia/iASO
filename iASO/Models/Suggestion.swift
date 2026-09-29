import Foundation

struct AppNameSuggestion: Identifiable {
    let id = UUID()
    let appName: String          // max 30 chars
    let subtitle: String         // max 30 chars
    let keywordField: String     // max 100 chars, comma-separated, for App Store Connect
    let keywords: [String]       // target keywords (badge display)
    let avgPopularity: Int
    let avgDifficulty: Int
    let avgOpportunity: Int
    let rationale: String
}
