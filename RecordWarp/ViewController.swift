//
//  ViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/7/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var auth = SPTAuth.defaultInstance()
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var webLoginUrl: URL?
    var appLoginUrl: URL?
    
    // can always improve the search function later
    
    @IBAction func tapLogin(_ sender: Any) {
        
        //in the tutorial - inside the complettion of this code they made use of the  auth.canHandle URL and sent it the redirect. Need to do some testing around this method to see if it really does anything useful
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
    
    func search(text: String){
        if(session.isValid()){
            SPTSearch.perform(withQuery: text, queryType: .queryTypeTrack, accessToken: session.accessToken) { (error, list) in
                let listPage = list as! SPTListPage
                let items = listPage.items as! [SPTPartialTrack]
                self.performSegue(withIdentifier: "showResults", sender: items)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showResults"){
            let resultsVC = segue.destination as! ResultsTableViewController
            resultsVC.results = sender as? [SPTPartialTrack]
        }
    }
    
    func setup() {
        SPTAuth.defaultInstance().clientID = Keys.clientID
        SPTAuth.defaultInstance().redirectURL = URL(string: Keys.redirectURL)
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope]
        webLoginUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        appLoginUrl = SPTAuth.defaultInstance().spotifyAppAuthenticationURL()
        
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
    }
    
    @objc func updateAfterFirstLogin(){
        if let sessionObj = UserDefaults.standard.object(forKey: "currentSession") {
            let sessionData = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
    }

    func initializePlayer(authSession: SPTSession){
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

extension ViewController : SPTAudioStreamingDelegate{
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
        self.player?.playSpotifyURI("spotifyURI", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            //handle error- if error is nil we should be playing
        })
    }
}

extension ViewController : SPTAudioStreamingPlaybackDelegate{
    
}

