import SwiftUI

struct KeywordResearchView: View {
    @Bindable var vm: KeywordResearchViewModel

    var body: some View {
        NavigationSplitView {
            ProjectSidebarView(vm: vm)
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
        } detail: {
            if vm.selectedProject != nil {
                ProjectKeywordView(vm: vm)
            } else {
                NoProjectSelectedView(vm: vm)
            }
        }
    }
}

// MARK: - Project Sidebar

struct ProjectSidebarView: View {
    @Bindable var vm: KeywordResearchViewModel
    @State private var showAddSheet = false
    @State private var newAppName = ""
    @FocusState private var addFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Projects")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if vm.projects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No projects yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Button("Add App") { showAddSheet = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(vm.projects) { project in
                            ProjectRow(
                                project: project,
                                isSelected: vm.selectedProjectId == project.id,
                                keywordCount: vm.selectedProjectId == project.id
                                    ? vm.keywords.count
                                    : project.savedKeywords.count
                            )
                            .onTapGesture {
                                vm.selectProject(project)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    vm.deleteProject(project)
                                } label: {
                                    Label("Delete Project", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .sheet(isPresented: $showAddSheet) {
            AddProjectSheet(isPresented: $showAddSheet) { appName in
                vm.addProject(appName: appName)
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: KeywordProject
    let isSelected: Bool
    let keywordCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(project.appName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)

                Text("\(keywordCount) keyword\(keywordCount == 1 ? "" : "s") · \(project.country.uppercased())")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.6))
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? Color.accentColor : .clear)
        )
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void
    @State private var appName = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("App Name")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField("e.g. Dance AI", text: $appName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onSubmit { submit() }
            }

            Text("Keywords you research will be saved separately for each project.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered).controlSize(.small)
                Spacer()
                Button("Create Project") { submit() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(appName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear { focused = true }
    }

    private func submit() {
        let name = appName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onAdd(name)
        isPresented = false
    }
}

// MARK: - No project selected

struct NoProjectSelectedView: View {
    @Bindable var vm: KeywordResearchViewModel
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 6) {
                Text("Select or create a project")
                    .font(.system(size: 14, weight: .medium))
                Text("Create a project for each app you want to research keywords for.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button("New Project") { showAddSheet = true }
                .buttonStyle(.borderedProminent).controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddSheet) {
            AddProjectSheet(isPresented: $showAddSheet) { appName in
                vm.addProject(appName: appName)
            }
        }
    }
}

// MARK: - Project keyword research area

struct ProjectKeywordView: View {
    @Bindable var vm: KeywordResearchViewModel
    @State private var inputText = ""
    @State private var showCountryPicker = false
    @State private var countrySearch = ""
    @FocusState private var inputFocused: Bool

    private var currentCountry: AppStoreCountry {
        appStoreCountries.first { $0.id == vm.country } ?? .init(id: "us", name: "United States", flag: "🇺🇸")
    }
    private var filteredCountries: [AppStoreCountry] {
        countrySearch.isEmpty ? appStoreCountries :
        appStoreCountries.filter {
            $0.name.localizedCaseInsensitiveContains(countrySearch) ||
            $0.id.localizedCaseInsensitiveContains(countrySearch)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top bar ──────────────────────────────────────────
            HStack(spacing: 10) {
                // Project name label
                if let project = vm.selectedProject {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(project.appName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Keyword input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                    TextField("Add keyword…", text: $inputText)
                        .textFieldStyle(.plain).font(.system(size: 13))
                        .focused($inputFocused)
                        .onSubmit { submitKeyword() }
                    if !inputText.isEmpty {
                        Button { inputText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary).font(.system(size: 13))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 0.5))
                .frame(maxWidth: 260)

                // Add button
                Button { submitKeyword() } label: {
                    if vm.isAddingKeyword {
                        HStack(spacing: 5) {
                            ProgressView().controlSize(.mini)
                            Text("Scoring…").font(.system(size: 12))
                        }
                    } else {
                        Label("Add", systemImage: "plus").font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderedProminent).controlSize(.small)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isAddingKeyword)

                Spacer()

                if let err = vm.addError {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 11)).foregroundStyle(.orange)
                }

                // Country picker
                Button { showCountryPicker.toggle() } label: {
                    HStack(spacing: 4) {
                        Text(currentCountry.flag).font(.system(size: 13))
                        Text(currentCountry.id.uppercased()).font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bordered).controlSize(.small)
                .popover(isPresented: $showCountryPicker, arrowEdge: .bottom) {
                    CountryPickerPopover(
                        selected: vm.country,
                        searchText: $countrySearch,
                        countries: filteredCountries,
                        onSelect: { c in
                            showCountryPicker = false; countrySearch = ""
                            Task { await vm.changeCountry(c.id) }
                        }
                    )
                }

                // Remove all
                if !vm.keywords.isEmpty {
                    Button { vm.removeAll() } label: {
                        Label("Clear All", systemImage: "trash").font(.system(size: 12))
                    }
                    .buttonStyle(.bordered).controlSize(.small).foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.background)

            Divider()

            // ── Content ──────────────────────────────────────────
            if vm.isRescoringAll {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Re-scoring keywords for \(currentCountry.name)…")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.keywords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 36)).foregroundStyle(.secondary.opacity(0.5))
                    VStack(spacing: 4) {
                        Text("No keywords yet")
                            .font(.system(size: 13, weight: .medium))
                        Text("Add keywords to research their popularity, difficulty, and opportunity.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).frame(maxWidth: 300)
                    }
                    Button("Add your first keyword") { inputFocused = true }
                        .buttonStyle(.bordered).controlSize(.regular)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            Text("Keyword").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Popularity").frame(width: 130, alignment: .leading)
                            Text("Difficulty").frame(width: 130, alignment: .leading)
                            Text("Opportunity").frame(width: 90, alignment: .leading)
                            Text("Apps in Ranking").frame(width: 160, alignment: .leading)
                            Spacer().frame(width: 36)
                        }
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)

                        Divider()

                        ForEach(vm.keywords) { kw in
                            ResearchKeywordRow(keyword: kw, onRemove: {
                                vm.removeKeyword(kw)
                            })
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .onChange(of: vm.addError) { _, err in
            if err != nil {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    vm.addError = nil
                }
            }
        }
    }

    private func submitKeyword() {
        let term = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        inputText = ""
        Task { await vm.addKeyword(term) }
    }
}

// MARK: - Research Keyword Row

struct ResearchKeywordRow: View {
    let keyword: Keyword
    let onRemove: () -> Void
    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text(keyword.term).font(.system(size: 13))
                    ClassificationBadge(cls: keyword.classification)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PopularityNumber(value: keyword.popularity)
                    .frame(width: 130, alignment: .leading)

                DifficultyNumber(value: keyword.difficulty)
                    .frame(width: 130, alignment: .leading)

                OpportunityNumber(value: keyword.opportunity)
                    .frame(width: 90, alignment: .leading)

                HStack(spacing: -6) {
                    ForEach(keyword.topApps.prefix(5)) { app in
                        AsyncImage(url: URL(string: app.artworkUrl60 ?? "")) { img in
                            img.resizable()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6).fill(.quaternary)
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
                    }
                    if keyword.topApps.count > 5 {
                        Text("+\(keyword.topApps.count - 5)")
                            .font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 10)
                    }
                }
                .frame(width: 160, alignment: .leading)

                Button { onRemove() } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isHovered ? .red : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .frame(width: 36, alignment: .center)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(isExpanded ? Color(nsColor: .controlBackgroundColor).opacity(0.4) : .clear)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() } }
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(keyword.topApps.prefix(10).enumerated()), id: \.element.id) { i, app in
                        HStack(spacing: 10) {
                            Text("#\(i + 1)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                            AsyncImage(url: URL(string: app.artworkUrl60 ?? "")) { img in
                                img.resizable()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                            }
                            .frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.trackName).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                Text(app.artistName).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if let count = app.userRatingCount, count > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(.yellow)
                                    Text(formatCount(count)).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        if i < keyword.topApps.prefix(10).count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16).padding(.bottom, 8)
            }
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
