import SwiftUI

enum AppTab: String, CaseIterable {
    case competitor = "Competitor Research"
    case keywords   = "Keyword Research"

    var icon: String {
        switch self {
        case .competitor: return "person.2.fill"
        case .keywords:   return "text.magnifyingglass"
        }
    }
}

struct ContentView: View {
    @State private var searchVM          = SearchViewModel()
    @State private var competitorVM      = CompetitorViewModel()
    @State private var keywordResearchVM = KeywordResearchViewModel()
    @State private var selectedApp: AppResult?
    @State private var activeTab: AppTab = .competitor

    var body: some View {
        VStack(spacing: 0) {
            // ── Tab bar ────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: activeTab == tab
                    ) {
                        activeTab = tab
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .background(.background)

            Divider()

            // ── Tab content ────────────────────────────────────────
            Group {
                switch activeTab {
                case .competitor:
                    NavigationSplitView {
                        SearchView(vm: searchVM, selectedApp: $selectedApp)
                            .frame(minWidth: 260)
                    } detail: {
                        if let app = selectedApp {
                            CompetitorView(app: app, vm: competitorVM)
                        } else {
                            EmptyStateView()
                        }
                    }
                    .onChange(of: selectedApp) { _, newApp in
                        guard let app = newApp else { return }
                        competitorVM.analyze(app: app)
                    }

                case .keywords:
                    KeywordResearchView(vm: keywordResearchVM)
                }
            }
        }
    }
}

// MARK: - Tab button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? Color(nsColor: .controlAccentColor).opacity(0.12)
                    : .clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: 7).stroke(Color(nsColor: .controlAccentColor).opacity(0.25), lineWidth: 0.5)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }
}
