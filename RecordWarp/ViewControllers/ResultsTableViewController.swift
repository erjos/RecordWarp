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

fileprivate enum SearchScope: String {
    case Tracks = "Tracks"
    case Artists = "Artists"
    case Albums = "Albums"
}

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
    
//    func isFiltering() -> Bool {
//        return searchController.isActive && !searchBarIsEmpty()
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        self.viewModel.results = viewModel.currentListPage?.items as? [SPTPartialTrack]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(UINib(nibName: "SearchResultsTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "resultCell")
        self.tableView.prefetchDataSource = self
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Songs, Albums or Artists"
        searchController.searchBar.scopeButtonTitles = [SearchScope.Tracks.rawValue, SearchScope.Artists.rawValue, SearchScope.Albums.rawValue]
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //TODO: move this search function to a different class
    func search(text: String, queryType: SPTSearchQueryType) {
        //not sure how well this session manager func will work
        guard let session = SessionManager.getCurrentSession() else {
            return
        }
        
        if(session.isValid()) {
            //TODO: move this method to interactor layer
            SPTSearch.perform(withQuery: text, queryType: queryType, accessToken: session.accessToken) { (error, list) in
                let listPage = list as! SPTListPage
                
                self.viewModel.currentListPage = listPage
                self.viewModel.results = self.viewModel.currentListPage?.items as? [SPTPartialTrack]
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.totalCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? SearchResultsTableViewCell else {
            fatalError("Did not create cell")
        }
        
        cell.resetCell()
        
        guard let results = viewModel.results else { return cell }
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
        
        return cell
    }

    //Right now this just plays the song
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var track: SPTPartialTrack!
        track = viewModel.results?[indexPath.row]
            
        SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
            
        })
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
    
    //Maps scope to query type
    func getQueryType() -> SPTSearchQueryType {
        let searchBar = self.searchController.searchBar
        let currentScopeIndex = searchBar.selectedScopeButtonIndex
        guard let scopes = searchBar.scopeButtonTitles else { return .queryTypeTrack }
        
        let currentScope = scopes[currentScopeIndex]
        
        switch currentScope {
        case SearchScope.Tracks.rawValue:
            return .queryTypeTrack
        case SearchScope.Artists.rawValue:
            return .queryTypeArtist
        case SearchScope.Albums.rawValue:
            return .queryTypeAlbum
        default:
            return .queryTypeTrack
        }
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
                
                //get the current scope - then map that current scope to the correct query type - then pass that query type in here
                
                self.search(text: searchController.searchBar.text!, queryType: self.getQueryType())
            }
        }
    }
}

extension ResultsTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.search(text: searchBar.text!, queryType: self.getQueryType())
    }
}
