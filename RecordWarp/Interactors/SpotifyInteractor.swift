//
//  SpotifyInteractor.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/9/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

//GENERAL IMPROVEMENT TODOS:
// implement feature to pause and resume downloads depending on whether the user still requires that content at the time
// implement feature to store the resume data object if the download fails
// consider what you could do to create this as a framework potentially

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
    
    //IDK about this search, might be better to just use the web api and then not worry about calling in the artists separately
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
    
    //Can probably put this in it's own class, doesnt really have a place in the interactor
    //TODO:// maybe add intelligence to know when to fetch a new one if this fails out though
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
    
    
    /**
      * Sends an API request to Spotify to search with a specific query.
     - Parameters:
        - query: The search text
        - completion: closure returned once the function has finished
        - data: The data returned from the service
        - response: UrlResponse object
        - error: The client error if one exists
    */
    func search(with query: String, types:  [SearchQueryType], completion: @escaping (_ data:Data?, _ response: URLResponse?, _ error: Error?)-> Void) {
        let urlPath = URL(string: "https://api.spotify.com/v1/search")
        let token = getSessionFromUserDefaults()?.accessToken
        let typesStrings = types.map { $0.rawValue }
        let typesHeader = typesStrings.joined(separator: ",")
        
        let values = ["type": typesHeader, "q": query]
        
        guard let urlRequest = try? SPTRequest.createRequest(for: urlPath, withAccessToken: token, httpMethod: "Get", values: values, valueBodyIsJSON: false, sendDataAsQueryString: true) else {
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
            
            if let unwrapData = data { //let mimeType = httpResponse.mimeType, mimeType == "text/html",
                
                if let decoded = self.decodeJsonToObject(unwrapData) as? [String: Any] {
                    //use SPTPartialAlbum
                    let track = decoded["albums"] as? [String: Any]
                    
                    //use SPTPartialTrack
                    let trackPage = decoded["tracks"] as? [String: Any]
                    
                    //use the codable models here maybe
                    let artists = decoded["artists"] as? [String: Any]
                }
                
            }
        }
        //converts data to a string
        task.resume()
    }
    
    //converts an object to JSON
    private func decodeJsonToObject(_ data: Data) -> Any? {
        let object = try? JSONSerialization.jsonObject(with: data, options: [])
        //looks like we might be able to cast this as a dictionary
        return object
    }
    
    private func decodeJson(_ responseData: Data) -> SearchResponseObject? {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(SearchResponseObject.self, from: responseData)
            return response
        } catch {
            print(error.localizedDescription)
        }
        return nil
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

//TODO: reduce this to one enum if you can... if not no worries one is used here the other for view purposes
//This is redundant with search scope that exists on the view controller currently
//might want to let users search for playlist just in case?
enum SearchQueryType: String {
    case Track = "track"
    case Album = "album"
    case Artist = "artist"
    case Playlist = "playlist"
}

protocol SpotifyProtocol {
    func getRecentlyPlayedTracks(_ accessToken: String)
    //maybe add the type that we want to search for?
    func search(_ query: String, success: @escaping (SPTListPage)->Void)
    
    func getNextPage(listPage: SPTListPage, success: @escaping (SPTListPage) -> Void)
    func search(with query: String, types: [SearchQueryType], completion: @escaping (_ data:Data?, _ response: URLResponse?, _ error: Error?)-> Void)
}
