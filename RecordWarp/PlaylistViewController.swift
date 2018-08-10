//
//  PlaylistViewController.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/9/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController {
    
    //Vote tracker - users can only vote x amount of times
    
    //users can only submit x amount of songs to a playlist
    
    //time limits to kick songs off the list and open up spaces for more
    
    //what if there was a weird power up shuffle that rearranges the order of all the songs
    
    //random function that gives you a random list of songs to start upvoting or down voting.
    
    // could auto generate by backfilling the lower end of the list with new songs to see if you like them any better... constantly improve playlists (smirk face) - would need some intelligence for that function

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "PlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: "playlistSong")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PlaylistViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistSong") as! PlaylistTableViewCell
        cell.delegate = self
        return cell
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.0
    }
}

extension PlaylistViewController: VoteActionDelegate {
    func upVote(cell: PlaylistTableViewCell) {
        guard let currentIndex = tableView.indexPath(for: cell) else { return }
        
        let newIndex = IndexPath(row: currentIndex.row - 1, section: currentIndex.section)
        
        guard newIndex.row >= 0 else {
            return
        }
        
        tableView.moveRow(at: currentIndex, to: newIndex)
    }
    
    func downVote(cell: PlaylistTableViewCell) {
        guard let currentIndex = tableView.indexPath(for: cell) else { return }
        let newIndex = IndexPath(row: currentIndex.row + 1, section: currentIndex.section)
        
        guard newIndex.row < tableView.numberOfRows(inSection: newIndex.section) else {
            return
        }
        
        tableView.moveRow(at: currentIndex, to: newIndex)
    }
}
