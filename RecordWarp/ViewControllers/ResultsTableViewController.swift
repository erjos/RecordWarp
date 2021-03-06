//
//  ResultsTableViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//
import UIKit

//load only the search for the active category to begin, but consider loading all three to improve perfomance maybe

enum SearchScope: String {
    case Tracks = "Tracks"
    case Artists = "Artists"
    case Albums = "Albums"
}

//Handle deletion events - what happens to the current query? Do we want to execute searches every 5 seconds if the text changes
//What do we do when the search goes back to empty? We want to maintain our current search results until the user decides to start typing again

class ResultsTableViewController: UITableViewController {
    
    var player: SPTAudioStreamingController?
    var viewModel = SptSearchViewModel()
    //TODO: consider decreasing the tiime here
    var throttler = Throttler(seconds: 5.3)
    var currentScope: SearchScope = .Tracks
    
    let searchController = UISearchController(searchResultsController: nil)
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    
//    func isFiltering() -> Bool {
//        return searchController.isActive && !searchBarIsEmpty()
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        
        //set the track results
        //self.viewModel.trackResults = viewModel.trackListPage?.items
        
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.currentScope {
        case .Albums:
            return viewModel.albumListPage?.totalCount ?? 0
        case .Artists:
            return viewModel.artistListPage?.totalCount ?? 0
        case .Tracks:
            return viewModel.trackListPage?.totalCount ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? SearchResultsTableViewCell else {
            fatalError("Did not create cell")
        }
        cell.resetCell()
        
        //get different results depending on the selected scope
        switch currentScope {
        case .Albums:
            guard let results = viewModel.albumResults else { return cell }
            guard indexPath.row < results.count else { return cell }
            let album = results[indexPath.row]
            cell.setCellForAlbum(album)
            self.viewModel.getImage(for: album) { (albumImage) in
                DispatchQueue.main.async {
                    if let updateCell = tableView.cellForRow(at: indexPath) as? SearchResultsTableViewCell {
                        updateCell.setCellImage(albumImage)
                    }
                }
            }
        case .Artists:
            guard let results = viewModel.artistResults else { return cell }
            guard indexPath.row < results.count else { return cell }
            let artist = results[indexPath.row]
            cell.setCellForArtist(artist)
            self.viewModel.getImage(for: artist) { (artistImage) in
                DispatchQueue.main.async {
                    if let updateCell = tableView.cellForRow(at: indexPath) as? SearchResultsTableViewCell {
                        updateCell.setCellImage(artistImage)
                    }
                }
            }
        case .Tracks:
            //This is some ugle shiite see if you can fix this
            guard let results = viewModel.trackResults else { return cell }
            guard indexPath.row < results.count else { return cell }
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
        var track: TrackPartial!
        track = viewModel.trackResults?[indexPath.row]
            
        SPTAudioStreamingController.sharedInstance()?.playSpotifyURI(track?.uri, startingWith: 0, startingWithPosition: 0, callback: { (err) in
            
        })
    }
}

private extension ResultsTableViewController {

    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        //TODO: change this based on scope
        return indexPath.row >= viewModel.trackResults?.count ?? 0
    }

    //calculates the visible cells that should be reloaded when you update the data source
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    func prefetchHelper<Item>(listPage: ListPageObject<Item>, scope:SearchScope) {
        guard listPage.hasNextPage else {
            return
        }
        viewModel.handlePrefetch(for: listPage, scope: scope) { (reload) in
            //reload the correct index paths
            DispatchQueue.main.async {
                let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: reload)
                self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
            }
        }
    }
}

extension ResultsTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        
        let shouldWeLoad = indexPaths.contains { (path) -> Bool in
            return self.isLoadingCell(for: path)
        }
        
        guard shouldWeLoad else {
            return
        }
        
        switch self.currentScope {
        case .Albums:
            guard let listP = viewModel.albumListPage else {
                return
            }
            prefetchHelper(listPage: listP, scope: self.currentScope)
        case .Artists:
            guard let listP = viewModel.artistListPage else {
                return
            }
            prefetchHelper(listPage: listP, scope: self.currentScope)
        case .Tracks:
            guard let listP = viewModel.trackListPage else {
                return
            }
            prefetchHelper(listPage: listP, scope: self.currentScope)
        }
    }
}

extension ResultsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        //guard against empty search?
        throttler.throttle {
            DispatchQueue.main.async {
                guard let text = searchController.searchBar.text,
                text != "" else { return }

                self.viewModel.executeSearch(text)
                self.tableView.reloadData()
            }
        }
    }
}

extension ResultsTableViewController: UISearchBarDelegate {
    
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        //set the current scope with updated value -- seems like this should be simpler
        guard let titles = searchBar.scopeButtonTitles else { return }
        let newScopeString = titles[selectedScope]
        guard let newScope = SearchScope(rawValue: newScopeString) else { return }
        self.currentScope = newScope
        self.tableView.reloadData()
        
        //TODO: because we run all our searches at once, we might not need to account for the text in this method and just determine what to show and hid in the table view
        guard let text = searchController.searchBar.text,
        text != "" else { return }
        
    }
}
