//
//  SptSearchViewModel.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/10/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//
import Foundation

class SptSearchViewModel {
    
    //var results:[SPTPartialTrack]?
    
    //three result possibilities depending on what we want to display
    var trackResults:[SPTPartialTrack]?
    var albumResults:[SPTPartialAlbum]?
    var artistResults:[SPTArtist]?
    
    //used to page results from the service, the items in the list page will change depending on how we query the search
    var currentListPage:SPTListPage?
    
    //TODO: filtering doesn't work right now
    var filteredTracks  = [SPTPartialTrack]()
    
    var imageCache = NSCache<NSString, UIImage>()
    
    //** returns total count table view uses to generate rows (max 3000 rows for efficiency)
    var totalCount: Int {
        guard let count = currentListPage?.totalListLength else {
            return 0
        }
        return (Int(count) > 3000) ? 3000 : Int(count)
    }
    
    //might need the full artist object to get this
    func getImageForArtist(artist: SPTPartialArtist, callback: @escaping (UIImage)->()) {
    }
    
    func getImageForTrack(track: SPTPartialTrack, callback: @escaping (UIImage)->()) {
        if let albumImage = track.album.covers.first as? SPTImage {
            
            if let image = self.imageCache.object(forKey: albumImage.imageURL.absoluteString as NSString) {
                callback(image)
            } else {
                self.fetchImage(url: albumImage.imageURL) { (image) in
                    //add the image to the cache
                    self.imageCache.setObject(image, forKey: albumImage.imageURL.absoluteString as NSString)
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
    private func calculateIndexPathsToReload(from newTracks: [SPTPartialTrack]) -> [IndexPath] {
        let startIndex = trackResults!.count - newTracks.count
        let endIndex = startIndex + newTracks.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    //** filters the content based on search text
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
    
        //TODO: take scope into account to switch between tracks,albums and artists
        guard let tracks = trackResults else {
            return
        }
    
        filteredTracks = tracks.filter({ (track) -> Bool in
            return track.name.lowercased().contains(searchText.lowercased())
        })
    }
    
    //** updates the data source and returns the list of rows to be updated on the table view
    func handleNextPage(_ listPage: SPTListPage) -> [IndexPath] {
        guard let newTracks = listPage.items as? [SPTPartialTrack] else {
            return []
        }
        //update data source
        self.trackResults?.append(contentsOf: newTracks)
        //uodate current listPage
        self.currentListPage = listPage
        //calculate indexPath to update
        let indexPathsToReload = self.calculateIndexPathsToReload(from: newTracks)
        return indexPathsToReload
    }
}
