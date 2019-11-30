//
//  ViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // complex part will be building the live updating playlist that is sending and receiving data. how to keep that in sync and working and all that ish.
    
    var auth = SPTAuth.defaultInstance()
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var webLoginUrl: URL?
    var appLoginUrl: URL?
    
    @IBOutlet weak var collection: UICollectionView!
    // can always improve the search function later
    
    @IBAction func tapLogin(_ sender: Any) {
        
        //in the tutorial - inside the completion of this code they made use of the  auth.canHandle URL and sent it the redirect. Need to do some testing around this method to see if it really does anything useful
        if SPTAuth.supportsApplicationAuthentication() {
            UIApplication.shared.open(appLoginUrl!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webLoginUrl!, options: [:], completionHandler: nil)
        }
    }
    
    @IBOutlet weak var searchField: UITextField!
    
    @IBAction func enterSearch(_ sender: Any) {
        guard let query = searchField.text else {
            return
        }
        
        search(text: query)
    }
    
    func search(text: String) {
        if(session.isValid()) {
            let interactor = SpotifyInteractor()
            interactor.search(with: text, types: [.Album,.Artist,.Track]) { (searchResult) in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "showResults", sender: searchResult)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showResults"){
            let resultsVC = segue.destination as! ResultsTableViewController
            let searchResults = sender as? SearchResponseObject
            
            //set all three list pages - introduce a method to do this in one line - or set the search results page on the view model?
            resultsVC.viewModel.albumListPage = searchResults?.albums
            resultsVC.viewModel.artistListPage = searchResults?.artists
            resultsVC.viewModel.trackListPage = searchResults?.tracks
        }
    }
    
    //TODO: make getting the session more accessible
    func setup() {
        SPTAuth.defaultInstance().clientID = Keys.clientID
        SPTAuth.defaultInstance().redirectURL = URL(string: Keys.redirectURL)
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, "user-read-recently-played"]
        webLoginUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        appLoginUrl = SPTAuth.defaultInstance().spotifyAppAuthenticationURL()
        
        
        //Maybe move this session getting method to somewhere more accessible
        guard let sessionData = UserDefaults.standard.object(forKey: "currentSession") as? Data else {
            print("nothing stored!")
            return
        }
        
        guard let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SPTSession else {
            print("No session!")
            return
        }
        
        self.session = session
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: Notification.Name(rawValue: "loginSuccessfull"), object: nil)
        
        //setup collection view
        self.collection.register(UINib(nibName: "MainCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "collectionCell")
        collection.delegate = self
        collection.reloadData()
        collection.dragDelegate = self
        collection.dropDelegate = self
        collection.dragInteractionEnabled = true
    }
    
    @objc func updateAfterFirstLogin() {
        if let sessionObj = UserDefaults.standard.object(forKey: "currentSession") {
            let sessionData = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
    }

    //move this into it's own class so we can instantiate view controllers wherever we want them
    func initializePlayer(authSession: SPTSession) {
        if self.player == nil {
            player = SPTAudioStreamingController.sharedInstance()
            player?.playbackDelegate = self
            player?.delegate = self
            try! player?.start(withClientId: auth?.clientID)
            player?.login(withAccessToken: authSession.accessToken)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : SPTAudioStreamingDelegate {
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
        // callback after successful login
        self.player?.playSpotifyURI("spotify:track:5vUYQW0FbyjkEkMpFrHDmY", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            //handle error- if error is nil we should be playing
        })
    }
}

extension ViewController : SPTAudioStreamingPlaybackDelegate{
    
}

//I think it didnt work because I didnt add the extension for the delegate at the same time
extension ViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       return collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: ((collectionView.frame.width-20)/3), height: ((collectionView.frame.width-20)/3))
        return size
    }
}

extension ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(row: row - 1, section: 0)
        }
        
        if coordinator.proposal.operation == .move {
            
            //TODO: implement logic for this function
            self.reorderItems(coordinator: coordinator, destination: destinationIndexPath, collectionView: collectionView)
        }
    }
    
    fileprivate func reorderItems(coordinator: UICollectionViewDropCoordinator, destination: IndexPath, collectionView: UICollectionView) {
        if let item = coordinator.items.first,
            let sourceIndex = item.sourceIndexPath {
            
            collectionView.performBatchUpdates({
                //remove items at: sourche ibndexPath.item
                //insert new item at destinationIndexPath.item
                
                collectionView.deleteItems(at: [sourceIndex])
                collectionView.insertItems(at: [destination])
            }, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = "this thing"
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
}
