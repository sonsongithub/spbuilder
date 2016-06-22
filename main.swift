//
//  main.swift
//  spbuilder
//
//  Created by sonson on 2016/06/22.
//  Copyright © 2016年 sonson. All rights reserved.
//

import Foundation


extension NSError {
    class func error(description: String) -> NSError {
        return NSError(domain:"com.sonson.spbuilder", code: 0, userInfo:["description":description])
    }
}

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
    
    var path: String {
        get {
            return "./\(name).playgroundbook"
        }
    }
    
    var contentsPath: String {
        get {
            return "./\(path)/Contents"
        }
    }
    
    var manifestPath: String {
        get {
            return "./\(path)/Contents/Manifest.plist"
        }
    }
    
    func plist() -> [String:AnyObject] {
        var dict: [String:AnyObject] = [
            "Name" : name,
            "Version" : version,
            "ContentIdentifier" : contentIdentifier,
            "ContentVersion" : contentVersion,
            "DeploymentTarget" : deploymentTarget,
            "Chapter" : [] as [String]
        ]
        if let imageReference = imageReference {
            dict["ImageReference"] = imageReference
        }
        return dict
    }
    
    func output() -> Bool {
        let nsdictionary = plist() as NSDictionary
        return nsdictionary.write(toFile: manifestPath, atomically: false)
    }
    
    func create() throws {
        // create book
        do {
            try FileManager.default().createDirectory(atPath: contentsPath, withIntermediateDirectories: true, attributes: nil)
            if !output() {
                throw NSError.error(description: "Can not write plist.")
            }
        } catch {
            throw error
        }
    }
    
    static func loadBook() throws -> Book {
        // load `Contents/Manifest.plist`
        return Book(name: "a", version: "1.0", contentIdentifier: "b", contentVersion: "1.0", deploymentTarget: "ios10.10")
    }
}

struct Chapter {
}

struct Page {
}

func bookExists(bookName: String) -> Bool {
    return FileManager.default().fileExists(atPath: "./\(bookName).playgroundbook")
}

func createBook(argc: Int, arguments: [String]) throws {
    if argc == 3 {
        if bookExists(bookName: arguments[1]) {
            throw NSError.error(description: "Book already exsits.")
        } else {
            do {
                try Book(name: arguments[1], version: "1.0", contentIdentifier: arguments[2], contentVersion: "1.0", deploymentTarget: "ios10.10").create()
            } catch {
                throw error
            }
        }
    } else {
        throw NSError.error(description: "Arguments is less.")
    }
}

func parseArguments() throws {
    var arguments :[String] = ProcessInfo.processInfo().arguments
    let argc = arguments.count - 1
    if argc >= 1 {
        print(arguments.first)
        arguments.removeFirst() // remove own path
        switch arguments[0] {
        case "create":
            do { try createBook(argc: argc, arguments: arguments) } catch { throw error }
        case "chapter":
            // add chapter to a book
            print(argc)
        case "page":
            // add page to a chapter
            print(argc)
        case "rm":
            // remove chapter from book
            // remove page from chapter
            print(argc)
        default:
            print(argc)
        }
    } else {
        throw NSError.error(description: "Arguments are less.")
    }
}

func main() {
    do {
        try parseArguments()
    } catch {
        print(error)
    }

//    let book = Book(name: "hoge", version: "1.0", contentIdentifier: "com.sonson.hoge", contentVersion: "1.0", deploymentTarget: "ios10.10")
//
//
//    print(arguments)
//
//    let dict = [
//        "Version" : "1.0",
//        "ContentIdentifier" : "com.sonson.hoge",
//        "Chapters" : ["a", "b"]
//    ]
//
//    let a: NSDictionary = dict as NSDictionary
//    a.write(toFile: "/Users/sonson/Desktop/hoge.plist", atomically: false)
}

main()
