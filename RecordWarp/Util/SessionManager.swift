//
//  SessionManager.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/20/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

//Evaluate if this is the best way to do this
class SessionManager {
    static func getCurrentSession()->SPTSession?{
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
}
