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
    
    func setCellImage(_ url: URL) {
        getData(from: url) { (data, response, err) in
            DispatchQueue.main.async() {
                //set the image on the main thread
                self.albumImage.image = UIImage(data: data!)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func setCellForTrack(_ track: SPTPartialTrack) {
        self.contentName.text = track.name
        self.additionalInfo.text = track.album.name
        if let artist = track.artists.first as? SPTArtist {
            self.infoTwo.text = artist.name
        }
        if let albumImage = track.album.covers.first as? SPTImage {
            setCellImage(albumImage.imageURL)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
