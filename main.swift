//
//  main.swift
//  spbuilder
//
//  Created by sonson on 2016/06/22.
//  Copyright © 2016年 sonson. All rights reserved.
//

import Foundation

struct Book {
    let name: String
    let version: String
    let contentIdentifier: String
    let contentVersion: String
    var imageReference: String?
    let deploymentTarget: String
    var chapters: [Chapter]
    
    init(name aName: String, version aVersion: String, contentIdentifier aContentIdentifier: String, contentVersion aContentVersion: String, imageReference anImageReference: String? = nil, deploymentTarget aDeploymentTarget: String) {
        name = aName
        version = aVersion
        contentIdentifier = aContentVersion
        contentVersion = aContentVersion
        imageReference = anImageReference
        deploymentTarget = aDeploymentTarget
        chapters = []
    }
    
    static func loadBook() throws -> Book? {
        // load `Contents/Manifest.plist`
        return nil
    }
}

struct Chapter {
    
}

let book = Book(name: "hoge", version: "1.0", contentIdentifier: "com.sonson.hoge", contentVersion: "1.0", deploymentTarget: "ios10.10")

let arguments :[String] = ProcessInfo.processInfo().arguments

print(arguments)

let dict = [
    "Version" : "1.0",
    "ContentIdentifier" : "com.sonson.hoge",
    "Chapters" : ["a", "b"]
]

let a: NSDictionary = dict as NSDictionary
a.write(toFile: "/Users/sonson/Desktop/hoge.plist", atomically: false)
