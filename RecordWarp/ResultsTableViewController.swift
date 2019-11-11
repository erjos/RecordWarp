//
//  ResultsTableViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

//NOTE: seems that we have an issue when the total number of results is too great - - figure out how to handle the total result so that it is a reasonable number and doesnt reach 97000 lol like when you search for queen

//implement a view model for table views and collections to improve

class ResultsTableViewController: UITableViewController {
    
    var player: SPTAudioStreamingController?
    
    var viewModel = SptSearchViewModel()
    
    lazy var spotifyInteractor: SpotifyProtocol = SpotifyInteractor()

    var throttler = Throttler(seconds: 5.3)
    
    let searchController = UISearchController(searchResultsController: nil)
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        viewModel.filterContentForSearchText(searchText, scope: scope)
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
        
        //set the results from the listpage we passed in
        self.viewModel.results = viewModel.currentListPage?.items as? [SPTPartialTrack]
        
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
        if isFiltering() {
            return viewModel.filteredTracks.count
        }
        return viewModel.totalCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let results = viewModel.results else {return cell}
        if isFiltering() {
            cell.textLabel?.text = viewModel.filteredTracks[indexPath.row].name
        } else {
            cell.textLabel?.text = results[indexPath.row].name
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
    //TODO: currently we're not using this, but we need to implement a loading state and this should be used to improve the UI when we do this
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


extension ResultsTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
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
