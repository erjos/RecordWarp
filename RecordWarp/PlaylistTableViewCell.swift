//
//  PlaylistTableViewCell.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 8/9/18.
//  Copyright © 2018 Ethan Joseph. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    weak var delegate: VoteActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func clickUp(_ sender: Any) {
        delegate?.upVote(cell: self)
    }
    @IBAction func clickDown(_ sender: Any) {
        delegate?.downVote(cell: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}

protocol VoteActionDelegate: class {
    func upVote(cell: PlaylistTableViewCell)
    func downVote(cell: PlaylistTableViewCell)
}
