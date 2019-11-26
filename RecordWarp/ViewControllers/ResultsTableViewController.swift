//
//  ResultsTableViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//
import UIKit

//load only the search for the active category to begin, but consider loading all three to improve perfomance maybe

fileprivate enum SearchScope: String {
    case Tracks = "Tracks"
    case Artists = "Artists"
    case Albums = "Albums"
}

//Handle deletion events - what happens to the current query? Do we want to execute searches every 5 seconds if the text changes
//What do we do when the search goes back to empty? We want to maintain our current search results until the user decides to start typing again

class ResultsTableViewController: UITableViewController {
    
    var player: SPTAudioStreamingController?
    var viewModel = SptSearchViewModel()
    lazy var spotifyInteractor: SpotifyProtocol = SpotifyInteractor()
    //TODO: consider decreasing the tiime here
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
        
        self.viewModel.trackResults = viewModel.currentListPage?.items as? [SPTPartialTrack]
        
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
        //TODO: clean this up, looks like you also have some method on the interactor you're using to grab the session... clean up your code yo! get this search working!!!
        guard let session = SessionManager.getCurrentSession() else {
            return
        }
        
        //this is just a test
        self.spotifyInteractor.search(with: text, types: [.Album,.Artist,.Track]) { (data, resp, err) in
            //biatch
        }
        
        if(session.isValid()) {
            //TODO: move this method to interactor layer
            
            SPTSearch.perform(withQuery: text, queryType: queryType, accessToken: session.accessToken) { (error, list) in
                
                //TODO: this crashes when the list is nil bc we're not handling the errors properly
                let listPage = list as! SPTListPage
                
                //this list page represents the list page for the new type
                self.viewModel.currentListPage = listPage
                
                if queryType == .queryTypeTrack {
                    self.viewModel.trackResults = self.viewModel.currentListPage?.items as? [SPTPartialTrack]
                } else if queryType == .queryTypeArtist {
                    self.viewModel.artistResults = self.viewModel.currentListPage?.items as? [SPTPartialArtist]
                } else if queryType == .queryTypeAlbum {
                    self.viewModel.albumResults = self.viewModel.currentListPage?.items as? [SPTPartialAlbum]
                }
                
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
        
        //get different results depending on the selected scope
        guard let results = viewModel.trackResults else { return cell }
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
        track = viewModel.trackResults?[indexPath.row]
            
        SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { (err) in
            
        })
    }
}

private extension ResultsTableViewController {

    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= viewModel.trackResults?.count ?? 0
    }

    //calculates the visible cells that should be reloaded when you update the data source
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    //keep this here, it gets data from the view
    private func getCurrentScope() -> SearchScope {
        let searchBar = self.searchController.searchBar
        let currentScopeIndex = searchBar.selectedScopeButtonIndex
        guard let scopes = searchBar.scopeButtonTitles else { return .Tracks }
        let currentScopeString = scopes[currentScopeIndex]
        return SearchScope(rawValue: currentScopeString) ?? .Tracks
    }
    
    //This can probably be moved to another class
    func getQueryType(from scope: SearchScope) -> SPTSearchQueryType {
        switch scope {
        case .Tracks:
            return .queryTypeTrack
        case .Artists:
            return .queryTypeArtist
        case .Albums:
            return .queryTypeAlbum
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
        //guard against empty search?
        throttler.throttle {
            DispatchQueue.main.async {
                guard let text = searchController.searchBar.text,
                text != "" else { return }
                let scope = self.getCurrentScope()
                let query = self.getQueryType(from: scope)
                self.search(text: text, queryType: query)
            }
        }
    }
}

extension ResultsTableViewController: UISearchBarDelegate {
    
    //We need to consider how we will handle switching back and forth between scopes if text changes vs if text doesnt change
    // could put a function in place that is responsible for checking if the text has changed since the last scope switch - or just pull in all three scopes data at once...
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let text = searchController.searchBar.text,
        text != "" else { return }
        let scope = getCurrentScope()
        let query = getQueryType(from: scope)
        self.search(text: searchBar.text!, queryType: query)
    }
}
