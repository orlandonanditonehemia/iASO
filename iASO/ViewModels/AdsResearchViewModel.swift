//
//  AdsResearchViewModel.swift
//  iASO
//
//  Created by profitfirst on 04/05/26.
//

import Foundation
import Observation

@Observable
@MainActor
class AdsResearchViewModel {
    var appName: String = ""
    var developerName: String = ""
    var results: [AdPlatform: AdsResearchResult] = [:]
    var isSearching: Bool = false
    var hasSearched: Bool = false

    private var searchTask: Task<Void, Never>?

    var loadingPlatforms: Set<AdPlatform> {
        Set(results.filter { $0.value.isLoading }.keys)
    }

    func search() {
        let name = appName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        searchTask?.cancel()

        // Set all platforms to loading immediately
        isSearching = true
        hasSearched = true
        for platform in AdPlatform.allCases {
            results[platform] = AdsResearchResult(
                platform: platform,
                status: .unknown,
                summary: "Searching...",
                isLoading: true
            )
        }

        searchTask = Task {
            // Search all 3 platforms in parallel, update UI as each completes
            await withTaskGroup(of: (AdPlatform, AdsResearchResult).self) { group in
                for platform in AdPlatform.allCases {
                    let appN = name
                    let devN = developerName.trimmingCharacters(in: .whitespaces)
                    group.addTask {
                        let result = await AdsResearchService.search(
                            appName: appN,
                            developerName: devN,
                            platform: platform
                        )
                        return (platform, result)
                    }
                }

                for await (platform, result) in group {
                    guard !Task.isCancelled else { break }
                    results[platform] = result
                }
            }

            if !Task.isCancelled {
                isSearching = false
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        searchTask = nil
        appName = ""
        developerName = ""
        results = [:]
        isSearching = false
        hasSearched = false
    }
}
