//
//  SpotifyResponseModels.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/25/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//
import Foundation

struct SearchResponseObject: Codable {
    var albums: ListPageObject<AlbumPartial>
    var artists: ListPageObject<Artist>
    var tracks: ListPageObject<TrackPartial>
    
    private enum CodingKeys: String, CodingKey {
        case albums
        case artists
        case tracks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        albums = try container.decode(ListPageObject.self, forKey: .albums)
        artists = try container.decode(ListPageObject.self, forKey: .artists)
        tracks = try container.decode(ListPageObject.self, forKey: .tracks)
    }
}

struct ListPageObject<Item :Codable>: Codable {
    var items: [Item]
    var next: String?
    var total: Int
    
    var hasNextPage: Bool {
        return next == nil ? false : true
    }
    
    var totalCount: Int {
        return (Int(total) > 3000) ? 3000 : Int(total)
    }
    
    private enum CondingKeys: String, CodingKey {
        case items
        case next
        case total
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Item].self, forKey: .items)
        next = try? container.decode(String.self, forKey: .next)
        total = try container.decode(Int.self, forKey: .total)
    }
    
    //TODO: is this the best way to do this?
    func requestNextPage(success: @escaping(ListPageObject<Item>?)->()) {
        let interactor = SpotifyInteractor()
        interactor.requestNextPage(url: self.next!, currentList: self) { (list) in
            success(list)
        }
    }
}

struct AlbumPagingObject: Codable, Pageable {
    var totalListLength: Int {
        return total
    }
    
    var hasNextPage: Bool {
        return next == nil ? false : true
    }
    
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
    
    func requestNextPage() -> Pageable? {
        //build the request to get the next page and then return the object?
        
        //create two individual functions responsible for making the request and decoding the object on a separate class
        return nil
    }
}

struct TrackPagingObject: Codable, Pageable {
    var totalListLength: Int {
        return total
    }
    
    var hasNextPage: Bool {
        return next == nil ? false : true
    }
    
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
    
    func requestNextPage() -> Pageable? {
        nil
    }
}

struct ArtistPagingObject: Codable, Pageable {
    var totalListLength: Int {
        return total
    }
    
    var hasNextPage: Bool {
        return next == nil ? false : true
    }
    
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
    
    func requestNextPage() -> Pageable? {
        return nil
    }
}

struct AlbumPartial: Codable {
    var artists: [Artist]
    var id: String
    var images: [ImageObject]
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
        artists = try container.decode([Artist].self, forKey: .artists)
        id = try container.decode(String.self, forKey: .id)
        images = try container.decode([ImageObject].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
        total_tracks = try container.decode(Int.self, forKey: .total_tracks)
    }
}

struct TrackPartial: Codable {
    var album: AlbumPartial
    var artists: [Artist]
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
        artists = try container.decode([Artist].self, forKey: .artists)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        uri = try container.decode(String.self, forKey: .uri)
    }
}

struct Artist: Codable {
    var id: String
    var images: [ImageObject]?
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case images
        case name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        images = try container.decodeIfPresent([ImageObject].self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
    }
}

struct ImageObject: Codable {
    var height: Int
    var url: String
    var width: Int
}

//paging objects should conform to this so that they can implement the function to get the next page
protocol Pageable {
    var totalListLength: Int { get }
    var hasNextPage: Bool { get }
    //requests the next page if one exists
    func requestNextPage() -> Pageable?
}
