import SwiftUI

struct GenerateView: View {
    @Bindable var vm: CompetitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("App Name & Subtitle suggestions")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    Task { await vm.generateSuggestions() }
                } label: {
                    if vm.isGenerating {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.mini)
                            Text("Generating…").font(.system(size: 12))
                        }
                    } else {
                        Label("Generate", systemImage: "sparkles")
                            .font(.system(size: 12))
                    }
                }
                .disabled(vm.keywords.isEmpty || vm.isAnalyzing || vm.isGenerating)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if vm.isGenerating {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Analyzing keyword opportunities…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if vm.suggestions.isEmpty && !vm.keywords.isEmpty {
                Text("Click Generate to get AI-powered App Name + Subtitle + Keyword suggestions.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
}

// MARK: - Suggestion card

struct SuggestionCard: View {
    let suggestion: AppNameSuggestion
    @State private var copiedName = false
    @State private var copiedKeywords = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── App Name ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel("App Name")
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(suggestion.appName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(suggestion.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        CharCounter(count: suggestion.appName.count, limit: 30)
                        CharCounter(count: suggestion.subtitle.count, limit: 30)
                    }
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            "\(suggestion.appName)\n\(suggestion.subtitle)",
                            forType: .string
                        )
                        copiedName = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedName = false }
                    } label: {
                        Label(copiedName ? "Copied" : "Copy", systemImage: copiedName ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                }
            }
            .padding(12)

            Divider()

            // ── Keyword Field ─────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SectionLabel("Keyword Field")
                    Text("(App Store Connect · max 100 chars)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    CharCounter(count: suggestion.keywordField.count, limit: 100)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(suggestion.keywordField, forType: .string)
                        copiedKeywords = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedKeywords = false }
                    } label: {
                        Label(copiedKeywords ? "Copied" : "Copy", systemImage: copiedKeywords ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                }

                // Keyword field as styled mono text
                Text(suggestion.keywordField)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator, lineWidth: 0.5))

                // Visual keyword badges breakdown
                FlowLayout(spacing: 4) {
                    ForEach(suggestion.keywordField.split(separator: ",").map(String.init), id: \.self) { kw in
                        Text(kw.trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 10))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.blue.opacity(0.08))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(12)

            Divider()

            // ── Scores + rationale ────────────────────────────
            HStack(spacing: 20) {
                ScoreMetric(label: "Popularity",  value: suggestion.avgPopularity,  color: .blue)
                ScoreMetric(label: "Difficulty",  value: suggestion.avgDifficulty,  color: diffColor(suggestion.avgDifficulty))
                ScoreMetric(label: "Opportunity", value: suggestion.avgOpportunity, color: oppColor(suggestion.avgOpportunity))
                Spacer()
                if !suggestion.rationale.isEmpty {
                    Text(suggestion.rationale)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 280)
                }
            }
            .padding(12)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
    }

    private func diffColor(_ v: Int) -> Color {
        v < 35 ? .green : v < 60 ? .orange : .red
    }
    private func oppColor(_ v: Int) -> Color {
        v >= 80 ? .green : v >= 60 ? Color(red: 0.5, green: 0.8, blue: 0.2) : v >= 40 ? .orange : .secondary
    }
}

// MARK: - Helpers

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

struct CharCounter: View {
    let count: Int
    let limit: Int

    var body: some View {
        Text("\(count)/\(limit)")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(count > limit ? .red : count > Int(Double(limit) * 0.85) ? .orange : .secondary)
    }
}

struct ScoreMetric: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
