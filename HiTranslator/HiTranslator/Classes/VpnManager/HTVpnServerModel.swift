//
//  FPVpnServerModel.swift
//  FastPro
//
//  Created by 万云辰 on 2022/1/20.
//

import Foundation
let HTFastServer = "Fastest Server"
var HTServerList = [HTServerModel(countryName: "New York", countryIcon: "US", host: "92.38.176.103"),
                    HTServerModel(countryName: "Chicago", countryIcon: "US", host: "5.8.41.63")]
//var HTServerList = [HTServerModel(countryName: "error country", countryIcon: "JP", host: " ")]

class HTServerModel: Codable {
    var countryName: String = ""
    var countryIcon: String = ""
    var host: String = ""
    var delay: Double = 0.0
    
    init(countryName: String?, countryIcon:String?, host: String?) {
        self.countryName = countryName ?? ""
        self.countryIcon = countryIcon ?? ""
        self.host = host ?? ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(code:) has not been impleted")
    }
}
