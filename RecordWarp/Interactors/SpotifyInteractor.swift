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
// consider increasing the payload to 50 instead of 20 to load more data before the first page loads

class SpotifyInteractor: SpotifyProtocol {
    
    var isDataFetching = false
    
    func handleClientError(_ error: Error) {
        //error with the client
    }
    
    func handleServerError(_ response: URLResponse?) {
        //server returned an error
    }
    
    //Add Error cases and handling to these methods
    
    //called by the view model? manages if data is fetching or not
    func getNextPage<Item>(listPage: ListPageObject<Item>, success: @escaping (SearchResponseObject?) -> Void) {
        guard !isDataFetching else {
            return
        }
        
        isDataFetching = true
        
        listPage.requestNextPage { (list) in
            //handle the list result
            //TODO: figure out how we'll handle errors as well to make sure that the data fetching indicator switches back
            self.isDataFetching = false
            success(list)
        }
    }
    
    /**
      * Sends an API request to Spotify to request the next paging object for a search - called from the paging object model.
     - Parameters:
        - url: the url of the next page in the search
        - currentList: the current list page that is displayed
        - completion: closure returned once the function has finished
        - data: The data returned from the service
        - response: UrlResponse object
        - error: The client error if one exists
    */
    func requestNextPage<Item>(url: String, currentList: ListPageObject<Item>, success: @escaping(_ listPage: SearchResponseObject?)->Void) {
        let urlPath = URL(string: url)
        let token = SessionManager.getCurrentSession()?.accessToken
        
        //TODO: test this
        guard let urlRequest = try? SPTRequest.createRequest(for: urlPath, withAccessToken: token, httpMethod: "Get", values: nil, valueBodyIsJSON: false, sendDataAsQueryString: false) else {//createRequest(for: urlPath, withAccessToken: token, httpMethod: "Get", values: [:], valueBodyIsJSON: true, sendDataAsQueryString: false) else {
            return
        }
        
        //TODO: consider breaking this handling into a method to avoid repitition
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlresponse, error) in
            if let err = error {
                self.handleClientError(err)
                
            }
            guard let httpResponse = urlresponse as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.handleServerError(urlresponse)
                    return
                    
            }
            if let unwrapData = data {
                //let type = self.getType(from: currentList)
                let responseObject: SearchResponseObject? = self.decodeSearchResponseJson(unwrapData)
                success(responseObject)
            }
        }
        task.resume()
    }
    
    //returns the enum for the type of listPage we're working with
    func getType(from listPage: Pageable) -> SearchQueryType {
        if let _ = listPage as? TrackPagingObject {
            return .Track
        } else if let _ = listPage as? AlbumPagingObject {
            return .Album
        } else if let _ = listPage as? ArtistPagingObject {
            return .Artist
        } else {
            //Default (should never execute)
            return .Track
        }
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
    func search(with query: String, types:  [SearchQueryType], completion: @escaping (_ searchObject: SearchResponseObject?)-> Void) {
        let urlPath = URL(string: "https://api.spotify.com/v1/search")
        //if user is not authorized, nothing happens
        let token = SessionManager.getCurrentSession()?.accessToken
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
            if let unwrapData = data {
                let responseObject = self.decodeSearchResponseJson(unwrapData)
                completion(responseObject)
            }
        }
        task.resume()
    }
    
    //DECODE OBJECTS
    private func decodeSearchResponseJson(_ responseData: Data) -> SearchResponseObject? {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(SearchResponseObject.self, from: responseData)
            return response
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    private func decodeJsonToObject(_ data: Data) -> Any? {
        let object = try? JSONSerialization.jsonObject(with: data, options: [])
        //looks like we might be able to cast this as a dictionary
        return object
    }
    
    
    ///NOT IN USE YET
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

enum SearchQueryType: String {
    case Track = "track"
    case Album = "album"
    case Artist = "artist"
    case Playlist = "playlist"
}

protocol SpotifyProtocol {
    func search(with query: String, types:  [SearchQueryType], completion: @escaping (_ searchObject: SearchResponseObject?)-> Void)
    func getNextPage<Item>(listPage: ListPageObject<Item>, success: @escaping (SearchResponseObject?) -> Void)
}
