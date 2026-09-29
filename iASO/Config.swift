import Foundation

// MARK: - Configuration
// To use this app, fill in your API key below.
// Get a key at: https://kie.ai
enum Config {
    // Your kie.ai API key — required for AI-powered features
    static let kieAPIKey: String = "YOUR_KIE_AI_API_KEY_HERE"

    // kie.ai Responses API endpoint (compatible with OpenAI Responses API)
    static let kieAPIEndpoint: String = "https://api.kie.ai/codex/v1/responses"
}
