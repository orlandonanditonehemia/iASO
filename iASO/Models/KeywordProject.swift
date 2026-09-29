import Foundation
import Combine

// MARK: - Keyword Project (persisted)

struct KeywordProject: Identifiable, Codable {
    var id: UUID = UUID()
    var appName: String
    var country: String = "us"
    var savedKeywords: [SavedKeyword] = []
    var createdAt: Date = Date()

    struct SavedKeyword: Identifiable, Codable {
        var id: UUID = UUID()
        var term: String
        var popularity: Int
        var difficulty: Int
        var opportunity: Int
        var classification: String
    }
}

// MARK: - Project Store

class KeywordProjectStore: ObservableObject {
    static let shared = KeywordProjectStore()

    @Published var projects: [KeywordProject] = []

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("iASO", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("keyword_projects.json")
    }()

    init() { load() }

    func addProject(appName: String) -> KeywordProject {
        let p = KeywordProject(appName: appName)
        projects.append(p)
        save()
        return p
    }

    func deleteProject(_ project: KeywordProject) {
        projects.removeAll { $0.id == project.id }
        save()
    }

    func updateProject(_ project: KeywordProject) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            save()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        try? data.write(to: saveURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([KeywordProject].self, from: data) else { return }
        projects = decoded
    }
}
