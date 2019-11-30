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
    
    weak var delegate: SearchResultsTableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func addSong(_ sender: Any) {
        //implement this delegate to get the callback and add the playlist
        delegate?.didTapAdd()
    }
    
    func resetCell() {
        self.albumImage.image = UIImage(named: "disc_icon")
        self.contentName.text = ""
        self.additionalInfo.text = ""
        self.infoTwo.text = ""
    }
    
    func setCellImage(_ image: UIImage) {
        self.albumImage.image = image
    }
    
    func setCellForTrack(_ track: TrackPartial) {
        self.contentName.text = track.name
        self.additionalInfo.text = track.album.name
        if let artist = track.artists.first as? SPTPartialArtist {
            self.infoTwo.text = artist.name
        }
    }
    
    func setCellForArtist(_ artist: SPTPartialArtist) {
        self.contentName.text = artist.name
    }
    
    func setCellForAlbum(_ album: SPTPartialAlbum) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}

protocol SearchResultsTableCellDelegate: class {
    func didTapAdd()
}
