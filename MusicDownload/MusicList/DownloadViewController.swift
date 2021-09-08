//
//  DownloadViewController.swift
//  MusicDownload
//
//  Created by anny on 2021/8/31.
//

import UIKit
import AVFoundation
import Foundation

class DownloadViewController: UIViewController {
    
    @IBOutlet weak var inputUrlTextField: UITextField!
    @IBOutlet weak var downLoadBtn: UIButton!
    @IBOutlet weak var musicTableView: UITableView!
    
    var url = ""
    var musicList = [MusicList]()
    var tplayer: AVAudioPlayer!
    var player: AVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initView()
        
        // Load MusicList Data
        if let musicList = MusicList.loadFromFile(){
            self.musicList = musicList
//            print("musicList :\(musicList)")
        }
    }
    
    func initView(){
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        backBarButtonItem.tintColor = .white
        self.navigationItem.backBarButtonItem = backBarButtonItem
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "icon_nav_close")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "icon_nav_close")
        
        downLoadBtn.setTitleColor(.lightGray, for: .disabled)
        downLoadBtn.setTitleColor(.systemOrange, for: .normal)
        downLoadBtn.isEnabled = false
        inputUrlTextField.delegate = self
        
        musicTableView.register(UINib(nibName: "MusicListTableViewCell", bundle: nil), forCellReuseIdentifier: "MusicListTableViewCell")
        musicTableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? MusicPlayerViewController {
            controller.selectIndexPath = sender as? IndexPath
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func showErrorAlert(title: String, message: String){
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func downLoadBtnPressed(_ sender: UIButton) {
        downLoadBtn.isEnabled = false
            
        if let mp3Url = URL(string: url){
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationUrl = documentsDirectoryURL.appendingPathComponent("0\(musicList.count + 1).mp3")
            
            musicList.append(MusicList(url: destinationUrl, time: ""))
            self.musicTableView.reloadData()

            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self,delegateQueue: nil)

            var request = URLRequest(url: mp3Url)
            request.addValue("bytes=0-", forHTTPHeaderField: "Range")
                   
            let downloadTask = session.downloadTask(with: request)
            downloadTask.resume()
        }
    }
}

extension DownloadViewController: URLSessionDownloadDelegate{
    // urlSession 下載完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectoryURL.appendingPathComponent("0\(musicList.count).mp3")
        // 下載 mp3 存檔到指定路徑
        do {
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            } catch {
                DispatchQueue.main.async {
                    self.showErrorAlert(title: "存檔發生錯誤", message: error.localizedDescription)
                }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let timeString = dateFormatter.string(from: Date())

        musicList[musicList.count - 1].time = timeString
        DispatchQueue.main.async {
            self.musicTableView.reloadData()
            self.downLoadBtn.isEnabled = true
        }
        MusicList.saveToFile(musicList: self.musicList)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
         if error != nil {
            let error = error! as NSError
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                self.musicList.remove(at: self.musicList.count - 1)
                MusicList.saveToFile(musicList: self.musicList)
                self.musicTableView.reloadData()
                self.downLoadBtn.isEnabled = true
                self.showErrorAlert(title: "下載失敗", message: error.localizedDescription)
            }
         }
    }
    // urlSession 下載進度
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // 獲取總長度
        let httpResponse = downloadTask.response as? HTTPURLResponse
        let totalRange = httpResponse?.value(forHTTPHeaderField: "Content-Range")
        if let totalRange = totalRange{
            let split = totalRange.components(separatedBy: "/").last!
            let written = Float(totalBytesWritten)
            let total = Float(split)!
            let progress = written / total
            
            DispatchQueue.main.async(){
                let indexPath = IndexPath(row: self.musicList.count - 1, section: 0)
                if let cell = self.musicTableView.cellForRow(at: indexPath) as? MusicListTableViewCell {
                    cell.progressView.isHidden = false
                    cell.updateDisplay(progress: progress)
                }
            }
        }
    }
}

extension DownloadViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ("已經下載 \(musicList.count) 首歌曲")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.white
        let header : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .gray
        
        let borderBottom = UIView(frame: CGRect(x:15, y:50, width: tableView.bounds.size.width - 30 , height: 0.8))
        borderBottom.backgroundColor = .systemGray2
        header.addSubview(borderBottom)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicListTableViewCell", for: indexPath) as! MusicListTableViewCell
        cell.initCell()
        
        if musicList[indexPath.row].time != ""{
            cell.progressView.isHidden = true
            cell.loadingLabel.text = "下載時間: \(musicList[indexPath.row].time)"
            
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationUrl = documentsDirectoryURL.appendingPathComponent("0\(indexPath.row + 1).mp3")
            
            cell.nameLabel.text = "Unknown Title"
            let musicAvset = AVAsset.init(url: destinationUrl)
            for musicDataItems in musicAvset.metadata{
                if let key = musicDataItems.key as? String, let value = musicDataItems.value{
                    if key == "APIC" { // 專輯封面
                        if let albumImage = UIImage(data: (musicDataItems.value) as! Data) {
                            cell.albumImage.image = albumImage
                        }
                    }else if key == "TIT2" { // title
                        cell.nameLabel.text = value as? String
                    }
                }
            }
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if musicList[indexPath.row].time != ""{
            performSegue(withIdentifier: "showMusicPlayer", sender: indexPath)
        }else{
            self.showErrorAlert(title: "尚未下載完成", message: "")
        }
    }
}

extension DownloadViewController: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        url = inputUrlTextField.text ?? ""
        if url == ""{
            downLoadBtn.isEnabled = false
        }else{
            downLoadBtn.isEnabled = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

