import Foundation
import Observation

@Observable
@MainActor
class KeywordResearchViewModel {
    // Project management
    var projects: [KeywordProject] = []
    var selectedProjectId: UUID? = nil

    // Current project's live keyword state
    var keywords: [Keyword] = []
    var country: String = "us"
    var isAddingKeyword: Bool = false
    var isRescoringAll: Bool = false
    var addError: String? = nil

    private let store = KeywordProjectStore.shared

    var selectedProject: KeywordProject? {
        guard let id = selectedProjectId else { return nil }
        return projects.first { $0.id == id }
    }

    init() {
        projects = store.projects
    }

    // MARK: - Project management

    func addProject(appName: String) {
        let p = store.addProject(appName: appName)
        projects = store.projects
        selectProject(p)
    }

    func deleteProject(_ project: KeywordProject) {
        store.deleteProject(project)
        projects = store.projects
        if selectedProjectId == project.id {
            selectedProjectId = projects.first?.id
            if let first = projects.first {
                loadProject(first)
            } else {
                keywords = []
                country = "us"
            }
        }
    }

    func selectProject(_ project: KeywordProject) {
        // Save current keywords back before switching
        saveCurrentKeywords()
        selectedProjectId = project.id
        loadProject(project)
    }

    private func loadProject(_ project: KeywordProject) {
        country = project.country
        // Convert saved keywords back to live Keyword objects (no scoring needed)
        keywords = project.savedKeywords.map { saved in
            let cls = classFromString(saved.classification)
            return Keyword(
                term: saved.term,
                popularity: saved.popularity,
                difficulty: saved.difficulty,
                opportunity: saved.opportunity,
                classification: cls,
                position: nil,
                topApps: []
            )
        }
    }

    private func saveCurrentKeywords() {
        guard let id = selectedProjectId,
              let idx = store.projects.firstIndex(where: { $0.id == id }) else { return }

        var updated = store.projects[idx]
        updated.country = country
        updated.savedKeywords = keywords.map { kw in
            KeywordProject.SavedKeyword(
                term: kw.term,
                popularity: kw.popularity,
                difficulty: kw.difficulty,
                opportunity: kw.opportunity,
                classification: kw.classification.rawValue
            )
        }
        store.updateProject(updated)
        projects = store.projects
    }

    // MARK: - Keyword management

    func addKeyword(_ term: String) async {
        let clean = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return }
        guard !keywords.contains(where: { $0.term == clean }) else {
            addError = "'\(clean)' already exists"
            return
        }
        guard isValidTerm(clean) else {
            addError = "Keyword too short or invalid"
            return
        }
        addError = nil
        isAddingKeyword = true

        do {
            let apps = try await iTunesService.shared.searchKeyword(clean, country: country)
            guard !apps.isEmpty else {
                addError = "No results found for '\(clean)'"
                isAddingKeyword = false
                return
            }
            let pop  = ScoringEngine.popularity(for: apps, keyword: clean)
            let diff = ScoringEngine.difficulty(for: apps, keyword: clean)
            let opp  = ScoringEngine.opportunity(popularity: pop, difficulty: diff)
            let cls  = ScoringEngine.classify(popularity: pop, difficulty: diff)
            let kw   = Keyword(term: clean, popularity: pop, difficulty: diff,
                               opportunity: opp, classification: cls,
                               position: nil, topApps: Array(apps.prefix(25)))
            insertSorted(kw)
            saveCurrentKeywords()
        } catch {
            addError = "Failed to score '\(clean)'"
        }
        isAddingKeyword = false
    }

    func removeKeyword(_ keyword: Keyword) {
        keywords.removeAll { $0.id == keyword.id }
        saveCurrentKeywords()
    }

    func removeAll() {
        keywords.removeAll()
        saveCurrentKeywords()
    }

    func changeCountry(_ newCountry: String) async {
        country = newCountry
        saveCurrentKeywords()
        guard !keywords.isEmpty else { return }

        isRescoringAll = true
        let terms = keywords.map { $0.term }
        keywords.removeAll()

        await withTaskGroup(of: Keyword?.self) { group in
            let semaphore = AsyncSemaphore(limit: 3)
            for term in terms {
                await semaphore.wait()
                group.addTask {
                    defer { Task { await semaphore.signal() } }
                    do {
                        let apps = try await iTunesService.shared.searchKeyword(term, country: newCountry)
                        guard !apps.isEmpty else { return nil }
                        let pop  = ScoringEngine.popularity(for: apps, keyword: term)
                        let diff = ScoringEngine.difficulty(for: apps, keyword: term)
                        let opp  = ScoringEngine.opportunity(popularity: pop, difficulty: diff)
                        let cls  = ScoringEngine.classify(popularity: pop, difficulty: diff)
                        return Keyword(term: term, popularity: pop, difficulty: diff,
                                       opportunity: opp, classification: cls,
                                       position: nil, topApps: Array(apps.prefix(25)))
                    } catch { return nil }
                }
            }
            for await result in group {
                if let kw = result { insertSorted(kw) }
            }
        }
        isRescoringAll = false
        saveCurrentKeywords()
    }

    private func insertSorted(_ kw: Keyword) {
        let idx = keywords.firstIndex { $0.opportunity < kw.opportunity } ?? keywords.endIndex
        keywords.insert(kw, at: idx)
    }

    private func isValidTerm(_ t: String) -> Bool {
        t.count >= 2 && t.count <= 30 && t.first?.isLetter == true
    }

    private func classFromString(_ s: String) -> ScoringEngine.KeywordClass {
        ScoringEngine.KeywordClass(rawValue: s) ?? .moderate
    }
}
