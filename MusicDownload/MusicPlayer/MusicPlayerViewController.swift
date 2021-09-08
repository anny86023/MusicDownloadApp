//
//  MusicPlayerViewController.swift
//  MusicDownload
//
//  Created by anny on 2021/9/6.
//

import UIKit
import AVFoundation

enum MusicInfoImg:String {
    case title = "ic_musicinfo_title_grey"
    case artist = "ic_musicinfo_artist_grey"
    case album = "ic_musicinfo_album_grey"
    case year = "ic_musicinfo_year_grey"
    case genre = "ic_musicinfo_genre_grey"
}

class MusicPlayerViewController: UIViewController {
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var musicTimeSlider: UISlider!
    @IBOutlet weak var musicTimeStartLabel: UILabel!
    @IBOutlet weak var musicTimeEndLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var musicInfoTableView: UITableView!
    
    var selectIndexPath: IndexPath!
    var player: AVAudioPlayer!
    var progressTimer: Timer?
    var musicInfoList: Array<MusicInfoImg> = [.title, .artist, .album, .year, .genre]
    var musicInfoDate = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            print(error)
        }
        
        self.initView()
        self.setMusic()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.progressTimer?.invalidate()
    }
    
    func initView() {
        // 設定漸層顏色
        let color1 =  UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1).cgColor
        let color2 =  UIColor(red: 255/255, green: 191/255, blue: 187/255, alpha: 1).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.frame
        gradientLayer.colors = [color1,color2]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playBtn.tintColor = .white
    }
    
    func setMusic(){
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectoryURL.appendingPathComponent("0\(selectIndexPath.row + 1).mp3")
        
        do{
            self.player = try AVAudioPlayer.init(contentsOf: destinationUrl)
            self.player.delegate = self
            player.prepareToPlay()

            // 設定 TimeSlider
            progressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimeSlider),userInfo: nil, repeats: true)
            player.play()
            
            musicTimeSlider.value = 0.0
            musicTimeSlider.minimumValue = 0.0
            musicTimeSlider.maximumValue = Float(player.duration)
            
            let minuteText = String(format: "%02d", Int(player.duration) / 60)
            let secondsText = String(format: "%02d", Int(player.duration) % 60)
            let timeText = minuteText + ":" + secondsText
            musicTimeEndLabel.text = timeText

        }catch let error as NSError{
            self.showErrorAlert(title: "Error", message: error.localizedDescription)
            playBtn.isEnabled = false
            musicTimeSlider.isEnabled = false
        }
        
        let musicAvset = AVAsset.init(url: destinationUrl)
        for musicDataItems in musicAvset.metadata{
            if let key = musicDataItems.key as? String, let value = musicDataItems.value{
                switch key {
                case "APIC": // 專輯封面
                    if let albumImage = UIImage(data: (musicDataItems.value) as! Data) {
                        self.albumImage.image = albumImage
                    }
                case "TIT2": // title
                    musicInfoDate["Title"] = value as? String ?? ""
                case "TPE1": // artist
                    musicInfoDate["Artist"] = value as? String ?? ""
                case "TALB": // albumName
                    musicInfoDate["Album"] = value as? String ?? ""
                case "TYER": // year
                    musicInfoDate["Year"] = value as? String ?? ""
                case "TCON": // genre
                    musicInfoDate["Genre"] = value as? String ?? ""
                default:
                    break
                }
            }
        }
        musicInfoTableView.reloadData()
    }
    
    @IBAction func playBtnPressed(_ sender: UIButton) {
        if player.isPlaying{
            player.pause()
            playBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
            progressTimer?.invalidate()
            progressTimer = nil
        }else{
            if progressTimer == nil {
                progressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimeSlider),userInfo: nil, repeats: true)
            }
            player.play()
            playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    @IBAction func musicTimeSliderChange(_ sender: UISlider) {
        player.currentTime = TimeInterval(sender.value)
        updatePlayTime()
    }

    @objc func updateTimeSlider(){
        updatePlayTime()
        musicTimeSlider.value = Float(player.currentTime)
    }
    
    func updatePlayTime(){
        let minuteText = String(format: "%02d", lround(player.currentTime) / 60)
        let secondsText = String(format: "%02d", lround(player.currentTime) % 60)
        let timeText = minuteText + ":" + secondsText
    
        musicTimeStartLabel.text = timeText
    }
    
    func showErrorAlert(title: String, message: String){
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
}

extension MusicPlayerViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer = nil
        progressTimer?.invalidate()
        playBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
}

extension MusicPlayerViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicPlayerTableViewCell", for: indexPath) as! MusicPlayerTableViewCell
        cell.iconImage.image = UIImage(named: musicInfoList[indexPath.row].rawValue)
        
        switch musicInfoList[indexPath.row] {
        case .title:
            cell.valueLabel.text = musicInfoDate["Title"] ?? "Unknown Title"
        case .artist:
            cell.valueLabel.text = musicInfoDate["Artist"] ?? "Unknown Artist"
        case .album:
            cell.valueLabel.text = musicInfoDate["Album"] ?? "Unknown Album"
        case .year:
            cell.valueLabel.text = musicInfoDate["Year"] ?? "Unknown Year"
        case .genre:
            cell.valueLabel.text = musicInfoDate["Genre"] ?? "Unknown Genre"
        }
        
        return cell
    }
    
}
