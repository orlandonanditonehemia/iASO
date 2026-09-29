import SwiftUI

struct CompetitorView: View {
    let app: AppResult
    @Bindable var vm: CompetitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompetitorHeaderView(app: vm.competitor ?? app)
            Divider()

            if vm.scrapeError {
                // Server error state — show retry
                ScrapeErrorView {
                    vm.retryAnalysis()
                }
            } else if vm.isAILoading {
                // Fetching metadata
                VStack(spacing: 12) {
                    ProgressView()
                    VStack(spacing: 4) {
                        Text("Fetching app metadata…")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        if vm.scrapeAttempt > 1 {
                            Text("Attempt \(vm.scrapeAttempt) of 3")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.isAnalyzing && vm.keywords.isEmpty {
                // Preparing candidates
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing keywords…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Keywords streaming in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        KeywordTableView(
                            keywords: vm.keywords,
                            country: $vm.country,
                            isAddingKeyword: vm.isAddingKeyword,
                            onAddKeyword: { kw in Task { await vm.addKeyword(kw) } },
                            onCountryChange: { c in Task { await vm.changeCountry(c, app: app) } },
                            scoringProgress: vm.isAnalyzing ? vm.scoringProgress : nil,
                            useGPT: $vm.useGPT
                        )
                        Divider()
                        GenerateView(vm: vm)
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 600)
    }
}

// MARK: - Scrape error view

struct ScrapeErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Could not fetch app data")
                    .font(.system(size: 14, weight: .medium))

                Text("The metadata service is temporarily unavailable.\nPlease try again in a moment.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onRetry()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Header

struct CompetitorHeaderView: View {
    let app: AppResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: app.artworkUrl100 ?? app.artworkUrl60 ?? "")) { img in
                    img.resizable()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 14).fill(.quaternary)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.trackName)
                        .font(.system(size: 15, weight: .semibold))

                    if let subtitle = app.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Text(app.artistName)
                            .font(.system(size: 11)).foregroundStyle(.tertiary)
                        if let genre = app.primaryGenreName {
                            Text("·").foregroundStyle(.quaternary).font(.system(size: 11))
                            Text(genre).font(.system(size: 11)).foregroundStyle(.tertiary)
                        }
                    }

                    HStack(spacing: 8) {
                        if let price = app.formattedPrice {
                            Label(price == "0" ? "Free" : price, systemImage: "tag")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        if let dateStr = app.currentVersionReleaseDate,
                           let date = ISO8601DateFormatter().date(from: dateStr) {
                            Label(relativeDate(date), systemImage: "clock.arrow.circlepath")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        if let dateStr = app.releaseDate,
                           let date = ISO8601DateFormatter().date(from: dateStr) {
                            Label(appAge(date), systemImage: "calendar")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if let rating = app.averageUserRating,
                   let count = app.userRatingCount, count > 0 {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 14, weight: .semibold))
                        Text(formatCount(count))
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text("ratings")
                            .font(.system(size: 10)).foregroundStyle(.tertiary)
                    }
                    .multilineTextAlignment(.center)
                }
            }

            if !app.metadataKeywords.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(app.metadataKeywords.prefix(20), id: \.self) { kw in
                        Text(kw)
                            .font(.system(size: 11))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(.blue.opacity(0.08))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return "Updated \(f.localizedString(for: date, relativeTo: Date()))"
    }

    private func appAge(_ date: Date) -> String {
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        let months = Calendar.current.dateComponents([.month], from: date, to: Date()).month ?? 0
        if years > 0 { return "\(years)y old" }
        return "\(months)mo old"
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
