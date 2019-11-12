//
//  SpotifyInteractor.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/9/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

//I think that we only want to have functions on the interactor for now, but what if the functions need knowledge of the view model so that the function can change to accomodate it?

class SpotifyInteractor: SpotifyProtocol {
    
    var isDataFetching = false
    
    func handleClientError(_ error: Error) {
        //error with the client
    }
    
    func handleServerError(_ response: URLResponse?) {
        //server returned an error
    }
    
    //Add Error cases and handling to these methods
    
    // gets the next page from an SPTListPage
    func getNextPage(listPage: SPTListPage, success: @escaping (SPTListPage) -> Void) {
        guard !isDataFetching else {
            return
        }
        
        isDataFetching = true
        
        guard let session = self.getSessionFromUserDefaults() else {
            return
        }
        
        listPage.requestNextPage(withAccessToken: session.accessToken) { (err, list) in
            //This crashes if there is a client error -
            
            let listPage = list as! SPTListPage
            success(listPage)
            self.isDataFetching = false
        }
    }
    
    //gets a single list page for an initial search query
    func search(_ query: String, success: @escaping (SPTListPage) -> Void) {
        guard let session = self.getSessionFromUserDefaults() else {
            return
        }
        
        SPTSearch.perform(withQuery: query, queryType: .queryTypeTrack, accessToken: session.accessToken) { (error, list) in
              //there are hasNextPage variables and request next page functions...
              //should be able to use this to provide a good way to move through the results
              let listPage = list as! SPTListPage
            
            //TODO: move this item initialization out of this method so that we have access to the list page and it's info on the view controller
              //let items = listPage.items as! [SPTPartialTrack]
            
            success(listPage)
          }
    }
    
    func getSessionFromUserDefaults() -> SPTSession? {
        guard let sessionData = UserDefaults.standard.object(forKey: "currentSession") as? Data else {
            print("nothing stored!")
            return nil
        }
        
        guard let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SPTSession else {
            print("No session!")
            return nil
        }
        
        return session
    }
        
  
    
    func getRecentlyPlayedTracks(_ accessToken: String) {
        //fetch recently played tracks
        guard let urlRequest = try? SPTRequest.createRequest(for: URL(string: "https://api.spotify.com/v1/me/player/recently-played"), withAccessToken: accessToken, httpMethod: "Get", values: [:], valueBodyIsJSON: true, sendDataAsQueryString: true) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlresponse, error) in
            if let err = error {
                self.handleClientError(err)
            }
            
            guard let httpResponse = urlresponse as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                self.handleServerError(urlresponse)
                return
            }
            
            if let mimeType = httpResponse.mimeType, mimeType == "text/html",
                let data = data,
                //converts data to a string
                let _ = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    //execute something on the main thread
                }
            }
        }
        task.resume()
    }
}

class SearchResultsViewModel {
    var isFetchInProgress = false
    var currentResultsPage: SPTListPage?
}

protocol SpotifyProtocol {
    func getRecentlyPlayedTracks(_ accessToken: String)
    //maybe add the type that we want to search for?
    func search(_ query: String, success: @escaping (SPTListPage)->Void)
    
    func getNextPage(listPage: SPTListPage, success: @escaping (SPTListPage) -> Void)
}
