//
//  ShouldTrainTableCellView.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 1/11/19.
//

import Cocoa

class ShouldTrainTableViewCell: NSTableCellView {
    @IBOutlet var checkButton: NSButton!
    
    override func prepareForReuse() {
        self.checkButton.integerValue = 0
        self.checkButton.identifier = NSUserInterfaceItemIdentifier("")
    }
}
