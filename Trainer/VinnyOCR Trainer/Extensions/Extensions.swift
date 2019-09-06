//
//  Extensions.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 1/11/19.
//

import Cocoa

extension String {
    static func random(ofLength length: Int, fromCharset charset: String) -> String {
        var ret = ""
        for _ in 0..<length {
            let indexNum = Int(arc4random_uniform(UInt32(charset.count)))
            let index = charset.index(charset.startIndex, offsetBy: indexNum)
            ret += String(charset[index])
        }
        return ret
    }
    
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    func firstIndex(of char: Character) -> Int? {
        guard let endIndex: String.Index = self.firstIndex(of: char) else {
            return nil
        }
        return self.distance(from: self.startIndex, to: endIndex)
    }
}

extension FloatingPoint {
    static func random(absMax: Self) -> Self {
        let max = abs(absMax)
        let random = Self(arc4random()) / Self(UINT32_MAX)
        return (-max) + (random * (max + max))
    }
}

extension NSImage {
    func saveAsPNG(toPath path: URL) -> Bool {
        guard let data = self.tiffRepresentation else {
            return false
        }
        
        guard let bitmap = NSBitmapImageRep(data: data) else {
            return false
        }
        
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }
        
        do {
            try pngData.write(to: path, options: [])
            return true
        } catch {
            return false
        }
    }
}

extension NSLock {
    func cycle() {
        self.lock()
        self.unlock()
    }
}

extension NSAlert {
    static func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}

extension NSOpenPanel {
    static var selectBackgrounds: NSOpenPanel {
        let ret = NSOpenPanel()
        
        ret.allowsMultipleSelection = true
        ret.canChooseDirectories = false
        ret.canChooseFiles = true
        ret.canCreateDirectories = false
        ret.showsHiddenFiles = false
        ret.showsResizeIndicator = true
        ret.title = "Select files"
        
        return ret
    }
    
    static var selectOutputDirectory: NSOpenPanel {
        let ret = NSOpenPanel()
        
        ret.allowsMultipleSelection = false
        ret.canChooseDirectories = true
        ret.canChooseFiles = false
        ret.canCreateDirectories = true
        ret.showsHiddenFiles = false
        ret.showsResizeIndicator = true
        ret.title = "Select directory"
        
        return ret
    }
    
    static var importExistingNetwork: NSOpenPanel {
        let ret = NSOpenPanel()
        
        ret.allowsMultipleSelection = false
        ret.canChooseDirectories = false
        ret.canChooseFiles = true
        ret.canCreateDirectories = false
        ret.showsHiddenFiles = false
        ret.showsResizeIndicator = true
        ret.title = "Select network"
        
        return ret
    }
    
    func runModal(completion: (NSOpenPanel) -> Void) {
        if self.runModal() == .OK {
            completion(self)
        }
    }
}
