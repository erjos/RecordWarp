//
//  SpotifyResponseModels.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/25/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

struct SearchResponseObject: Codable {
    var albums: AlbumPagingObject
    var artists: ArtistPagingObject
    var tracks: TrackPagingObject
}

struct AlbumPagingObject: Codable {
    var items: [AlbumPartial]
    var next: String?
    var total: Int
       
    private enum CodingKeys: String, CodingKey {
        case items
        case next
        case total
    }
       
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([AlbumPartial].self, forKey: .items)
        next = try? container.decode(String.self, forKey: .next)
        total = try container.decode(Int.self, forKey: .total)
    }
}

struct TrackPagingObject: Codable {
    var items: [TrackPartial]
    var next: String?
    var total: Int
       
    private enum CodingKeys: String, CodingKey {
        case items
        case next
        case total
    }
       
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([TrackPartial].self, forKey: .items)
        next = try? container.decode(String.self, forKey: .next)
        total = try container.decode(Int.self, forKey: .total)
    }
}

struct ArtistPagingObject: Codable {
    var items: [Artist]
    var next: String?
    var total: Int
       
    private enum CodingKeys: String, CodingKey {
        case items
        case next
        case total
    }
       
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Artist].self, forKey: .items)
        next = try? container.decode(String.self, forKey: .next)
        total = try container.decode(Int.self, forKey: .total)
    }
}

struct AlbumPartial: Codable {
    var artists: [[String:String]]
    var id: String
    var images: [[String:String]]
    var name: String
    var total_tracks: Int
    
    private enum CodingKeys: String, CodingKey {
        case artists
        case id
        case images
        case name
        case total_tracks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        artists = try container.decode([[String:String]].self, forKey: .artists)
        id = try container.decode(String.self, forKey: .id)
        images = try container.decode([[String:String]].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
        total_tracks = try container.decode(Int.self, forKey: .total_tracks)
    }
}

struct TrackPartial: Codable {
    var album: AlbumPartial
    var artists: [[String:String]]
    var id: String
    var name: String
    var uri: String
    
    private enum CodingKeys: String, CodingKey {
        case album
        case artists
        case id
        case name
        case uri
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        album = try container.decode(AlbumPartial.self, forKey: .album)
        artists = try container.decode([[String:String]].self, forKey: .artists)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        uri = try container.decode(String.self, forKey: .uri)
    }
}

struct Artist: Codable {
    var id: String
    var images: [[String: String]]
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case images
        case name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        images = try container.decode([[String:String]].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
    }
}
