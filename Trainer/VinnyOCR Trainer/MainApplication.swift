//
//  MainApplication.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 1/15/19.
//

import Cocoa

class MainApplication: NSApplication {
    @IBAction func quit(_ sender: NSMenuItem) {
        NSApp.perform(#selector(terminate(_:)), with: nil, afterDelay: 0.0)
    }
}
