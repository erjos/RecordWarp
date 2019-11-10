//
//  ResultsTableViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

class ResultsTableViewController: UITableViewController {
    
    var player: SPTAudioStreamingController?
    var results:[SPTPartialTrack]?
    
    //This number should be updated to include the correct delay for the UI
    var throttler = Throttler(seconds: 5.3)
    
    var filteredTracks  = [SPTPartialTrack]()
    
    //Might use these later
    var filteredAlbums = [SPTPartialAlbum]()
    var filteredArtists = [SPTPartialArtist]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //returns index paths of new tracks that we are adding to the data source
    private func calculateIndexPathsToReload(from newTracks: [SPTPartialTrack]) -> [IndexPath] {
        let startIndex = results!.count - newTracks.count
        let endIndex = startIndex + newTracks.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }

    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        //TODO: take scope into account to switch between tracks,albums and artists
        
        guard let tracks = results else {
            return
        }
        
        filteredTracks = tracks.filter({ (track) -> Bool in
            return track.name.lowercased().contains(searchText.lowercased())
        })
        
        self.tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Songs, Albums or Artists"
        searchController.searchBar.scopeButtonTitles = ["All", "Tracks", "Artists", "Albums"]
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.tableView.prefetchDataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return the total count on the result so we can build the table appropriately
        guard let count = results?.count else { print ("No Data") ; return 0 }
        
        if isFiltering() {
            return filteredTracks.count
        }
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let results = results else {return cell}
        
        if isFiltering() {
            cell.textLabel?.text = filteredTracks[indexPath.row].name
        } else {
            cell.textLabel?.text = results[indexPath.row].name
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var track: SPTPartialTrack!
        if isFiltering(){
            track = self.filteredTracks[indexPath.row]
            
            SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
                //
            })
        } else {
            track = self.results?[indexPath.row]
            
            SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
                //
            })
        }
    }
    
}

private extension ResultsTableViewController {
    
    
  func isLoadingCell(for indexPath: IndexPath) -> Bool {
    return indexPath.row >= results?.count ?? 0
  }

    //calculates cells that need to reload when you receive a new page
  func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
    let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
    let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
    return Array(indexPathsIntersection)
  }
    
}


extension ResultsTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        //fetch the next page of the data - the tutorial uses one method, but we can use the function attached to the list page to request the next page I think...
    }
}

extension ResultsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        throttler.throttle {
            DispatchQueue.main.async {
                self.filterContentForSearchText(searchController.searchBar.text!)
            }
        }
    }
}

extension ResultsTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}
