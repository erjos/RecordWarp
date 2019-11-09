//
//  SpotifyInteractor.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/9/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

class SpotifyInteractor: SpotifyProtocol {
    func handleClientError(_ error: Error) {
        //error with the client
    }
    
    func handleServerError(_ response: URLResponse?) {
        //server returned an error
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

protocol SpotifyProtocol {
    func getRecentlyPlayedTracks(_ accessToken: String)
}
