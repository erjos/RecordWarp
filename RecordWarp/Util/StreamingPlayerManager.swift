//
//  StreamingPlayerManager.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/9/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

class StreamingPlayerManager {
    var player: SPTAudioStreamingController?
    var auth = SPTAuth.defaultInstance()
    
    func initializePlayer(authSession: SPTSession) {
        if self.player == nil {
            player = SPTAudioStreamingController.sharedInstance()
            
            //Delegate needs to be set to a view controller p sure
            
            //player?.playbackDelegate = self
            //player?.delegate = self
            try! player?.start(withClientId: auth?.clientID)
            player?.login(withAccessToken: authSession.accessToken)
        }
    }
}
