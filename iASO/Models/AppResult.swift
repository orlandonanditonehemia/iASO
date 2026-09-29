//
//  AppResult.swift
//  iASO
//
//  Created by profitfirst on 03/05/26.
//

import Foundation

struct AppResult: Identifiable, Decodable, Hashable {
    let id: Int
    let trackName: String
    let artistName: String
    let artworkUrl60: String?
    let artworkUrl100: String?
    let primaryGenreName: String?
    let averageUserRating: Double?
    let userRatingCount: Int?
    let currentVersionReleaseDate: String?
    let releaseDate: String?
    let description: String?
    let version: String?
    let price: Double?
    let formattedPrice: String?
    let minimumOsVersion: String?
    let fileSizeBytes: String?

    // Filled after separate fetch
    var subtitle: String? = nil
    var metadataKeywords: [String] = []

    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case trackName, artistName, artworkUrl60, artworkUrl100
        case primaryGenreName, averageUserRating, userRatingCount
        case currentVersionReleaseDate, releaseDate, description, version
        case price, formattedPrice, minimumOsVersion, fileSizeBytes
    }
}

struct iTunesSearchResponse: Decodable {
    let resultCount: Int
    let results: [AppResult]
}
