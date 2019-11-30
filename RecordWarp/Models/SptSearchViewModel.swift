//
//  SptSearchViewModel.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/10/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//
import Foundation

class SptSearchViewModel{
    
    //item objects for each result type
    var trackResults:[TrackPartial]?
    var albumResults:[AlbumPartial]?
    var artistResults:[Artist]?
    
    //this is where we'll define the generic type of the item
    var trackListPage: ListPageObject<TrackPartial>?
    var albumListPage: ListPageObject<AlbumPartial>?
    var artistListPage: ListPageObject<Artist>?
    
    var imageCache = NSCache<NSString, UIImage>()
    
    //TODO: remove reference to the interactor on the view model - write tests that can be mocked with the spotify protocol
    lazy var spotifyInteractor: SpotifyProtocol = SpotifyInteractor()
    
    //might need the full artist object to get this
    func getImageForArtist(artist: SPTPartialArtist, callback: @escaping (UIImage)->()) {
    
    }
    
    func getImageForTrack(track: TrackPartial, callback: @escaping (UIImage)->()) {
        if let albumImage = track.album.images.first {
            
            if let image = self.imageCache.object(forKey: albumImage.url as NSString) {
                callback(image)
            } else {
                let url = URL(string: albumImage.url)
                self.fetchImage(url: url!) { (image) in
                    //add the image to the cache
                    self.imageCache.setObject(image, forKey: albumImage.url as NSString)
                    callback(image)
                }
            }
        }
    }
    
    //fetches the image using the get data method and returns a UIImage - adds to cache
    func fetchImage(url: URL, success: @escaping (UIImage)->()) {
        getData(from: url) { (data, response, err) in
            //TODO: remove force unwrap and add error handling
            guard let image = UIImage(data: data!) else {
                return
            }
            success(image)
        }
    }
    
    //gets data from url
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    //** returns index paths of new tracks that we are adding to the data source
    private func calculateIndexPathsToReload<Item>(from newItems: [Item], updatedResults: [Item]) -> [IndexPath] {
        let startIndex = updatedResults.count - newItems.count
        let endIndex = startIndex + newItems.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    func handlePrefetch<Item>(for listPage: ListPageObject<Item>?, scope: SearchScope, completion: @escaping ([IndexPath])->Void) {
        guard let listP = listPage else {
            return
        }
        
        guard listP.hasNextPage else {
            return
        }
        
        self.spotifyInteractor.getNextPage(listPage: listP) { (newListPage) in
            var indexPathsToReload: [IndexPath]
            
            //TODO: we need to update the current list page on the view model (otherwise the fetch will only work once), but right now we have a circular call - doesnt need to be happening and not sure why it is... we need to make this easier to understand so that we can debug it
            
            switch scope {
            case .Albums:
                let newItems = newListPage?.items as? [AlbumPartial] ?? []
                self.albumResults?.append(contentsOf: newItems)
                indexPathsToReload = self.calculateIndexPathsToReload(from: newItems, updatedResults: self.albumResults ?? [])
            case .Artists:
                let newItems = newListPage?.items as? [Artist] ?? []
                self.artistResults?.append(contentsOf: newItems)
                indexPathsToReload = self.calculateIndexPathsToReload(from: newItems, updatedResults: self.artistResults ?? [])
            case .Tracks:
                let newItems = newListPage?.items as? [TrackPartial] ?? []
                self.trackResults?.append(contentsOf: newItems)
                indexPathsToReload = self.calculateIndexPathsToReload(from: newItems, updatedResults: self.trackResults ?? [])
            }
            completion(indexPathsToReload)
        }
    }
}
