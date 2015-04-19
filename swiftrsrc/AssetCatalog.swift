//
//  AssetCatalog.swift
//  swiftrsrc
//
//  Created by Indragie on 1/25/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import Foundation

private let ImagesetFileExtension = "imageset"
private let NameSuffix = "Catalog"

/// Xcode asset catalog (*.xcassets)
struct AssetCatalog {
    let URL: NSURL
    let name: String
    private let tree: FSTree
    
    /// Failable initializer that returns `nil` if the URL cannot be accessed.
    init?(URL: NSURL, error: NSErrorPointer) {
        if let tree = FSTree(URL: URL, error: error) {
            self.tree = tree.filter { node in
                if node.isLeaf { return false }
                let ext = node.URL.pathExtension
                return ext == nil || count(ext!) == 0 || isValidImageSet(tree: node)
            }
            self.URL = URL
            self.name = URL.fileName! + NameSuffix
        } else {
            return nil
        }
    }
}

private func isValidImageSet(#tree: FSTree) -> Bool {
    if (tree.URL.pathExtension == ImagesetFileExtension) {
        /* Originally written as:
        
           return elementPassingTest(tree.children) { $0.URL.lastPathComponent == "Contents.json" }
                    .chainMap { $0.URL }
                    .chainMap { NSData(contentsOfURL: $0) }
                    .chainMap { NSJSONSerialization.JSONObjectWithData($0, options: .allZeros, error: nil) as? NSDictionary }
                    .chainMap { $0["images"] as? [NSDictionary] }
                    .chainMap { elementPassingTest($0) { $0["filename"] != nil } } != nil
        
          This kills the compiler/indexer. (Xcode 6.1.1, Swift 1.1)
        */
        if let contentsURL = elementPassingTest(tree.children, { $0.URL.lastPathComponent == "Contents.json" })?.URL {
            if let data = NSData(contentsOfURL: contentsURL) {
                if let JSON = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: nil) as? NSDictionary {
                    if let images = JSON["images"] as? [NSDictionary] {
                        return elementPassingTest(images, { $0["filename"] != nil }) != nil
                    }
                }
            }
        }
    }
    return false
}

// MARK: Printable

extension AssetCatalog: Printable {
    var description: String {
        return "AssetCatalog{name=\(name), URL=\(URL)}"
    }
}

// MARK: CodeGeneratorType

extension AssetCatalog: CodeGeneratorType {
    func generateCodeForPlatform(platform: Platform) -> String {
        return _generateCode(platform, tree, 0)
    }
}

private func _generateCode(platform: Platform, tree: FSTree, level: Int) -> String {
    let name = tree.URL.fileName!
    let camelCaseName = name.camelCaseString
    let imageClass: String = {
        switch platform {
        case .iOS: return "UIImage"
        case .OSX: return "NSImage"
        }
    }()
    
    let indentNewline: String -> String = { $0.indent(level) + "\n" }
    
    if tree.URL.pathExtension == ImagesetFileExtension {
        return indentNewline("static var \(camelCaseName): \(imageClass) { return \(imageClass)(named: \"\(name)\")! }")
    } else {
        let name = level == 0 ? (camelCaseName + NameSuffix) : camelCaseName
        var code = indentNewline("struct \(name) {")
        code += reduce(tree.children, "", { $0 + _generateCode(platform, $1, level + 1) })
        code += indentNewline("}")
        return code
    }
}
