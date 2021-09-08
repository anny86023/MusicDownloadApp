//
//  Define.swift
//  MusicDownload
//
//  Created by anny on 2021/9/5.
//

import Foundation

struct MusicList:Codable {
    var url: URL
    var time: String
    
    static func saveToFile(musicList:[MusicList]){
        let saveMusicList = try? JSONEncoder().encode(musicList)
        UserDefaults.standard.set(saveMusicList, forKey: "MusicList")
    }
    
    static func loadFromFile() -> [MusicList]?{
        guard let loadDate = UserDefaults.standard.data(forKey: "MusicList") else {return nil}
        return try? JSONDecoder().decode([MusicList].self, from: loadDate)
    }
    
}
