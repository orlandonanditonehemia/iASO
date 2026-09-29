//
//  AdsResearchView.swift
//  iASO
//
//  Created by profitfirst on 04/05/26.
//

import SwiftUI

struct AdsResearchView: View {
    @State private var vm = AdsResearchViewModel()
    @FocusState private var appNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ── Search bar ─────────────────────────────────────
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("App name (e.g. Dance AI)", text: $vm.appName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .focused($appNameFocused)
                            .onSubmit { vm.search() }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 0.5))
                    .frame(maxWidth: 280)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: "person")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("Developer name (optional)", text: $vm.developerName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit { vm.search() }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 0.5))
                    .frame(maxWidth: 240)
                }

                Button {
                    vm.search()
                } label: {
                    if vm.isSearching {
                        HStack(spacing: 5) {
                            ProgressView().controlSize(.mini)
                            Text("Searching…").font(.system(size: 12))
                        }
                    } else {
                        Label("Search Ads", systemImage: "binoculars")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(vm.appName.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSearching)

                Spacer()

                // Experimental badge
                Label("Experimental", systemImage: "flask")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())

                if vm.hasSearched {
                    Button {
                        vm.clear()
                        appNameFocused = true
                    } label: {
                        Text("Clear").font(.system(size: 12))
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(.background)

            Divider()

            // ── Content ────────────────────────────────────────
            if !vm.hasSearched {
                AdsResearchEmptyView {
                    appNameFocused = true
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ad presence for \"\(vm.appName)\"")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Searched across Apple Search Ads, Meta, and TikTok ad libraries using AI web search.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20).padding(.top, 16)

                        // Platform cards
                        ForEach(AdPlatform.allCases, id: \.self) { platform in
                            if let result = vm.results[platform] {
                                AdPlatformCard(result: result, platform: platform)
                                    .padding(.horizontal, 20)
                            }
                        }

                        // Disclaimer
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("Results are AI-generated via web search and may not be fully accurate. Verify directly on each platform.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 20)
                    }
                }
            }
        }
        .frame(minWidth: 600)
    }
}

// MARK: - Empty state

struct AdsResearchEmptyView: View {
    let onFocus: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "binoculars")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.6))

            VStack(spacing: 6) {
                Text("Ads Research")
                    .font(.system(size: 14, weight: .medium))
                Text("Enter an app name to check if it's running ads on Apple Search Ads, Meta (Facebook/Instagram), and TikTok.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            Button("Start searching") { onFocus() }
                .buttonStyle(.bordered).controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Platform card

struct AdPlatformCard: View {
    let result: AdsResearchResult
    let platform: AdPlatform
    @State private var isExpanded = false

    private var statusColor: Color {
        switch result.status {
        case .running:  return .green
        case .notFound: return .secondary
        case .unknown:  return .orange
        case .error:    return .red
        }
    }

    private var statusIcon: String {
        switch result.status {
        case .running:  return "checkmark.circle.fill"
        case .notFound: return "xmark.circle.fill"
        case .unknown:  return "questionmark.circle.fill"
        case .error:    return "exclamationmark.triangle.fill"
        }
    }

    private var statusText: String {
        switch result.status {
        case .running:  return "Running Ads"
        case .notFound: return "No Ads Found"
        case .unknown:  return "Unknown"
        case .error:    return "Error"
        }
    }

    private var platformColor: Color {
        switch platform {
        case .appleSearchAds: return .blue
        case .meta:           return Color(red: 0.23, green: 0.35, blue: 0.7)
        case .tiktok:         return Color(red: 0.9, green: 0.1, blue: 0.4)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                // Platform icon
                Image(systemName: platform.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(platformColor)
                    .frame(width: 32, height: 32)
                    .background(platformColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(platform.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                    Text(platform.searchURL)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if result.isLoading {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.mini)
                        Text("Searching…")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Ad count badge
                    if result.status == .running, let count = result.adCount {
                        Text("\(count) ads")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }

                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11))
                        Text(statusText)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !result.isLoading else { return }
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
            }

            // Expanded: full summary
            if isExpanded && !result.isLoading {
                Divider().padding(.horizontal, 14)
                VStack(alignment: .leading, spacing: 8) {
                    if !result.summary.isEmpty && result.summary != "Searching..." {
                        Text(result.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    if let lastSeen = result.lastSeen, !lastSeen.isEmpty, lastSeen != "null" {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("Last seen: \(lastSeen)")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.tertiary)
                    }
                    // Link to platform
                    Button {
                        if let url = URL(string: platform.searchURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Open \(platform.rawValue)")
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}
