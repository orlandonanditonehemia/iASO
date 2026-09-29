//
//  SearchView.swift
//  iASO
//
//  Created by profitfirst on 03/05/26.
//

import SwiftUI

struct SearchView: View {
    @Bindable var vm: SearchViewModel
    @Binding var selectedApp: AppResult?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search competitor app…", text: $vm.query)
                    .onSubmit { Task { await vm.search() } }
                if vm.isLoading {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(10)
            .background(.background)

            Divider()

            List(vm.results, selection: $selectedApp) { app in
                AppRow(app: app).tag(app)
            }
            .listStyle(.sidebar)
        }
    }
}

struct AppRow: View {
    let app: AppResult

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: app.artworkUrl60 ?? "")) { img in
                img.resizable()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10).fill(.quaternary)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.trackName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(app.artistName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Search a competitor app to start")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
