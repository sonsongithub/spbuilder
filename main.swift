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
    
    init(name aName: String, version aVersion: String, contentIdentifier aContentIdentifier: String, contentVersion aContentVersion: String, imageReference anImageReference: String? = nil, deploymentTarget aDeploymentTarget: String, chapters arrayChapters: [String] = []) {
        name = aName
        version = aVersion
        contentIdentifier = aContentVersion
        contentVersion = aContentVersion
        imageReference = anImageReference
        deploymentTarget = aDeploymentTarget
        print(arrayChapters)
        chapters = arrayChapters.map({ (name) -> Chapter in
            let title = name.replacingOccurrences(of: ".playgroundchapter", with: "")
            print("\(name) => \(title)")
            return Chapter(name: title)
        })
        print(chapters)
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
    
    func getChapter(name: String) throws -> Chapter {
        for i in 0..<chapters.count {
            if chapters[i].name == name {
                return chapters[i]
            }
        }
        throw NSError.error(description: "Not found")
    }
    
    mutating func add(chapter: Chapter) throws {
        chapters.append(chapter)
        do {
            try writeManifest()
        } catch {
            throw error
        }
    }
    
    func manifest() -> [String:AnyObject] {
        var dict: [String:AnyObject] = [
            "Name" : name,
            "Version" : version,
            "ContentIdentifier" : contentIdentifier,
            "ContentVersion" : contentVersion,
            "DeploymentTarget" : deploymentTarget,
            "Chapters" : chapters.map({ $0.name + ".playgroundchapter" }) as [String]
        ]
        if let imageReference = imageReference {
            dict["ImageReference"] = imageReference
        }
        return dict
    }
    
    func writeManifest(at: String = "./Contents/Manifest.plist") throws {
        let nsdictionary = manifest() as NSDictionary
        if !nsdictionary.write(toFile: at, atomically: false) {
            throw NSError.error(description: "Can not write plist.")
        }
    }
    
    func create() throws {
        // create book
        do {
            try FileManager.default().createDirectory(atPath: contentsPath, withIntermediateDirectories: true, attributes: nil)
            try writeManifest(at: "./\(path)/Contents/Manifest.plist")
        } catch {
            throw error
        }
    }
}

struct Chapter {
    let name: String
    var pages: [Page]
    let version: String
    
    init(name aName: String, version aVersion: String = "1.0", pages arrayPages: [String] = []) {
        print("Chapter name = \(aName)")
        name = aName
        version = aVersion
        pages = arrayPages.map({ (name) -> Page in
            let title = name.replacingOccurrences(of: ".playgroundpage", with: "")
            print("\(name) => \(title)")
            return Page(name: title, chapterName: name)
        })
    }

    func manifest() -> [String:AnyObject] {
        let dict: [String:AnyObject] = [
            "Name" : name,
            "Version" : version,
            "Pages" : pages.map({ $0.name + ".playgroundpage" }) as [String]
        ]
        return dict
    }
    
    mutating func add(page: Page) throws {
        pages.append(page)
        do {
            try writeManifest()
        } catch {
            throw error
        }
    }
    
    func writeManifest() throws {
        let at = "./Contents/Chapters/\(name).playgroundchapter"
        do {
            try FileManager.default().createDirectory(atPath: at, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        let nsdictionary = manifest() as NSDictionary
        print(nsdictionary)
        print(at)
        if !nsdictionary.write(toFile: at + "/Manifest.plist", atomically: false) {
            throw NSError.error(description: "Chapter: Can not write plist.")
        }
    }
}

struct Page {
    let name: String
    let version: String
    let chapterName: String
    
    init(name aName: String, version aVersion: String = "1.0", chapterName aChapterName: String) {
        name = aName
        version = aVersion
        chapterName = aChapterName
    }
    
    func manifest() -> [String:AnyObject] {
        let dict: [String:AnyObject] = [
            "Name" : name,
            "Version" : version,
            ]
        return dict
    }
    
    func writeManifest() throws {
        let at = "./Contents/Chapters/\(chapterName).playgroundchapter/Pages/\(name).playgroundpage/"
        do {
            try FileManager.default().createDirectory(atPath: at, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        let nsdictionary = manifest() as NSDictionary
        if !nsdictionary.write(toFile: at + "/Manifest.plist", atomically: false) {
            throw NSError.error(description: "Page : Can not write plist.")
        }
    }
}

func bookExists(bookName: String) -> Bool {
    return FileManager.default().fileExists(atPath: "./\(bookName).playgroundbook")
}

func loadBook() throws -> Book {
    let bookManifestPath = "./Contents/Manifest.plist"
    if FileManager.default().isReadableFile(atPath: bookManifestPath) {
        // open
        guard let dict = NSDictionary(contentsOfFile: bookManifestPath) else { throw NSError.error(description: "Can not parse Manifest.plist.") }
        
        if let name = dict["Name"] as? String,
            version = dict["Version"] as? String,
            contentIdentifier = dict["ContentIdentifier"] as? String,
            contentVersion = dict["ContentVersion"] as? String,
            deploymentTarget = dict["DeploymentTarget"] as? String {
            
            let imageReference = dict["ImageReference"] as? String
            let chapters = dict["Chapters"] as? [String] ?? [] as [String]
            
            return Book(name: name, version: version, contentIdentifier: contentIdentifier, contentVersion: contentVersion, imageReference: imageReference, deploymentTarget: deploymentTarget, chapters: chapters)
            
        } else {
            throw NSError.error(description: "Manifest.plist is deformed.")
        }
    } else {
        throw NSError.error(description: "Can not find Manifest.plist. Moved inside playgroundbook's directory.")
    }
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

func addChapter(argc: Int, arguments: [String]) throws {
    if argc == 2 {
        do {
            var book = try loadBook()
            let chapter = Chapter(name: arguments[1])
            try book.add(chapter: chapter)
            try book.writeManifest()
            try chapter.writeManifest()
        } catch {
            throw error
        }
    } else {
        throw NSError.error(description: "Arguments is less.")
    }
}

func addPage(argc: Int, arguments: [String]) throws {
    if argc == 3 {
        do {
            let book = try loadBook()
            var chapter = try book.getChapter(name: arguments[1])
            let page = Page(name: arguments[2], chapterName: chapter.name)
            try chapter.add(page: page)
            try page.writeManifest()
        } catch {
            throw error
        }
    } else {
        throw NSError.error(description: "Arguments is less.")
    }
}

func parseArguments() throws {
    var arguments :[String] = ProcessInfo.processInfo().arguments
    print(arguments.first)
    let argc = arguments.count - 1
    if argc >= 1 {
        arguments.removeFirst() // remove own path
        switch arguments[0] {
        case "create":
            do { try createBook(argc: argc, arguments: arguments) } catch { throw error }
        case "chapter":
            do { try addChapter(argc: argc, arguments: arguments) } catch { throw error }
        case "page":
            do { try addPage(argc: argc, arguments: arguments) } catch { throw error }
        case "rm":
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
}

main()
