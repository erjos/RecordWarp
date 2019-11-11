//
//  SptSearchViewModel.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/10/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//
import Foundation

class SptSearchViewModel {
    
    var results:[SPTPartialTrack]?
    var currentListPage:SPTListPage?
    //Might use these later to help with filtering
    var filteredAlbums = [SPTPartialAlbum]()
    var filteredArtists = [SPTPartialArtist]()
    
    var filteredTracks  = [SPTPartialTrack]()
    
    //** returns total count table view uses to generate rows (max 3000 rows for efficiency)
    var totalCount: Int {
        guard let count = currentListPage?.totalListLength else {
            return 0
        }
        return (Int(count) > 3000) ? 3000 : Int(count)
    }
    
    //** returns index paths of new tracks that we are adding to the data source
    private func calculateIndexPathsToReload(from newTracks: [SPTPartialTrack]) -> [IndexPath] {
        let startIndex = results!.count - newTracks.count
        let endIndex = startIndex + newTracks.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    //** filters the content based on search text
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
    
        //TODO: take scope into account to switch between tracks,albums and artists
        guard let tracks = results else {
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
        self.results?.append(contentsOf: newTracks)
        //uodate current listPage
        self.currentListPage = listPage
        //calculate indexPath to update
        let indexPathsToReload = self.calculateIndexPathsToReload(from: newTracks)
        return indexPathsToReload
    }
}
