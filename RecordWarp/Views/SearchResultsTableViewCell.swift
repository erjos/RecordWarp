//
//  SearchResultsTableViewCell.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/10/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import UIKit

class SearchResultsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var contentName: UILabel!
    @IBOutlet weak var additionalInfo: UILabel!
    @IBOutlet weak var infoTwo: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func addSong(_ sender: Any) {
    }
    
    func setCellImage(_ image: UIImage) {
        self.albumImage.image = image
        
        //move this somewhere else

    }
    
    func setCellForTrack(_ track: SPTPartialTrack) {
        self.contentName.text = track.name
        self.additionalInfo.text = track.album.name
        if let artist = track.artists.first as? SPTPartialArtist {
            self.infoTwo.text = artist.name
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
