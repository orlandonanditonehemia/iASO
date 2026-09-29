//
//  SearchViewModel.swift
//  iASO
//
//  Created by profitfirst on 03/05/26.
//

import Foundation
import Observation

@Observable
class SearchViewModel {
    var query: String = ""
    var results: [AppResult] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            results = try await iTunesService.shared.searchApps(term: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
