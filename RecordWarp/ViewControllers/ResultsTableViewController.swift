//
//  ResultsTableViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

//maybe instead of filtering our list we actually want to use the throttler to determine when to submit the search to spotify.
//we could have three tabs available - when you select an artist or an album you are taken to a list of tracks that correspond to them
//The add button is only visible for tracks for the time being

//load only the search for the active category to begin, but consider loading all three

class ResultsTableViewController: UITableViewController {
    
    var player: SPTAudioStreamingController?
    var viewModel = SptSearchViewModel()
    lazy var spotifyInteractor: SpotifyProtocol = SpotifyInteractor()
    var throttler = Throttler(seconds: 5.3)
    let searchController = UISearchController(searchResultsController: nil)
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "Tracks") {
        //modify this method to update the search via spotify rather than filter the results we have here
        viewModel.filterContentForSearchText(searchText, scope: scope)
        self.tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //setup search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Songs, Albums or Artists"
        searchController.searchBar.scopeButtonTitles = ["Tracks", "Artists", "Albums"]
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        //set the results from the listpage we passed in
        self.viewModel.results = viewModel.currentListPage?.items as? [SPTPartialTrack]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        //self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.tableView.register(UINib(nibName: "SearchResultsTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "resultCell")
        self.tableView.prefetchDataSource = self
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
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
        if isFiltering() {
            return viewModel.filteredTracks.count
        }
        return viewModel.totalCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? SearchResultsTableViewCell else {
            fatalError("Did not create cell")
        }
        
        cell.resetCell()
        
        guard let results = viewModel.results else { return cell }
        
        if isFiltering() {
            let track = viewModel.filteredTracks[indexPath.row]
            cell.setCellForTrack(track)
        } else {
            //CRASHED HERE - index out of range - I think i just fixed it
            if indexPath.row < results.count {
                let track = results[indexPath.row]
                cell.setCellForTrack(track)
                self.viewModel.getImageForTrack(track: track) { (albumImage) in
                    
                    DispatchQueue.main.async {
                        if let updateCell = tableView.cellForRow(at: indexPath) as? SearchResultsTableViewCell {
                            updateCell.setCellImage(albumImage)
                        }
                    }
                }
            }
        }
        return cell
    }

    //Right now this just plays the song
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var track: SPTPartialTrack!
        if isFiltering(){
            track = viewModel.filteredTracks[indexPath.row]
            
            SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
                //
            })
        } else {
            track = viewModel.results?[indexPath.row]
            
            SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
                //
            })
        }
    }
    
}

private extension ResultsTableViewController {

    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= viewModel.results?.count ?? 0
    }

    //calculates the visible cells that should be reloaded when you update the data source
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
  }
}

//Used to create infinite scroll
extension ResultsTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        
        let shouldWeLoad = indexPaths.contains { (path) -> Bool in
            return self.isLoadingCell(for: path)
        }
        
        guard shouldWeLoad else {
            return
        }
        
        //fetch the next page of the data - the tutorial uses one method, but we can use the
        guard let listP = viewModel.currentListPage else {
            return
        }
        //check if there is a next page
        guard viewModel.currentListPage!.hasNextPage else {
            return
        }
        //fetch the next page and update the view model and table view accordingly
        self.spotifyInteractor.getNextPage(listPage: listP) { (nextPage) in
            let reload = self.viewModel.handleNextPage(nextPage)
            let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: reload)
            tableView.reloadRows(at: indexPathsToReload, with: .automatic)
        }
    }
}

//used to update search results based on user input - need to modify how this work to acutally run the search on this page
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
