//
//  File.swift
//  
//
//  Created by eidd5180 on 01/07/2020.
//

import Foundation

enum Endpoint: String {

    case legacyStatus = "http://carto.strasmap.eu/remote.amf.json/Parking.geometry"
    case legacyLocation = "http://carto.strasmap.eu/remote.amf.json/Parking.status"

    case location = "https://data.strasbourg.eu/api/records/1.0/search/?dataset=parkings"
    case status = "https://data.strasbourg.eu/api/records/1.0/search/?dataset=occupation-parkings-temps-reel"
}
