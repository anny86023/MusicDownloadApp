//
//  MusicListTableViewCell.swift
//  MusicDownload
//
//  Created by anny on 2021/9/4.
//

import UIKit

class MusicListTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initCell(){
        albumImage.image = nil
        progressView.progress = 0.0
        nameLabel.text = "Unknown Title"
    }
    
    func updateDisplay(progress: Float) {
        progressView.progress = progress
        loadingLabel.text = "下載進度: \(String(format: "%.f", progress * 100)) %"
    }
    
}

protocol DownLoadProgress {
    func progress(sender: MusicListTableViewCell)
}
