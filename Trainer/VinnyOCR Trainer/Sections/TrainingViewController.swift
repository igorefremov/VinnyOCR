//
//  TrainingViewController.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 1/11/19.
//

import Cocoa
import CreateML
import VinnyOCR

class TrainingViewController: NSViewController {
    @IBOutlet var fontTableView: NSTableView!
    
    @IBOutlet var trainingBackgroundTextField: NSTextField!
    @IBOutlet var trainingBackgroundButton: NSButton!
    
    @IBOutlet var trainingDirectoryTextField: NSTextField!
    @IBOutlet var trainingDirectoryButton: NSButton!
    @IBOutlet var makeTrainingDataButton: NSButton!
    
    @IBOutlet var accuracyLabel: NSTextField!
    
    private let fonts = NSFontManager.shared.availableFonts.filter({ !$0.hasPrefix(".") }).filter({ NSFont(name: $0, size: 0)?.displayName != nil })
    
    private var selectedFonts = [String]()
    private var selectedBackgrounds = [NSImage]()
    private var outputDirectory: String?
    
    private var worker: TrainingWorker?
    private var isWorking: Bool { return self.worker != nil }
    
    private var updateableElements: [NSControl?] {
        return [self.trainingBackgroundButton, self.trainingDirectoryButton]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accuracyLabel.stringValue = ""
    }
    
    @IBAction func makeTrainingDataButtonPressed(_ sender: NSButton) {
        !self.isWorking ? self.startMakingData() : self.stopMakingData()
    }
    
    @IBAction func shouldTrainCheckButtonPressed(_ sender: NSButton) {
        guard !self.isWorking else {
            sender.integerValue = (sender.integerValue == 0 ? 1 : 0)
            return
        }
        
        if sender.integerValue == 0, let location = self.selectedFonts.firstIndex(of: sender.identifier!.rawValue) {
            self.selectedFonts.remove(at: location)
        } else {
            self.selectedFonts.append(sender.identifier!.rawValue)
        }
        
        self.updateComponentsWhileConfiguring()
    }
    
    @IBAction func selectBackgroundImagesButtonPressed(_ sender: NSButton) {
        NSOpenPanel.selectBackgrounds.runModal { (panel) in
            let noBackgrounds = {
                self.trainingBackgroundTextField.stringValue = "No Background Images Selected"
                self.updateComponentsWhileConfiguring()
            }
            
            guard !panel.urls.isEmpty else {
                noBackgrounds()
                return
            }
            
            self.selectedBackgrounds = panel.urls.compactMap({ NSImage(contentsOfFile: $0.path) })
            guard !self.selectedBackgrounds.isEmpty else {
                noBackgrounds()
                return
            }
            
            self.trainingBackgroundTextField.stringValue = "\(self.selectedBackgrounds.count) Backgrounds Loaded"
        }
        
        self.updateComponentsWhileConfiguring()
    }
    
    @IBAction func selectDirectoryButtonPressed(_ sender: NSButton) {
        NSOpenPanel.selectOutputDirectory.runModal { (panel) in
            self.outputDirectory = panel.directoryURL!.path
            if !self.outputDirectory!.hasSuffix("/") {
                self.outputDirectory! += "/"
            }
            
            self.trainingDirectoryTextField.stringValue = self.outputDirectory!
        }
        
        self.updateComponentsWhileConfiguring()
    }
}

extension TrainingViewController {
    private func startMakingData() {
        guard !self.isWorking else {
            return
        }
        
        self.accuracyLabel.stringValue = ""
        
        let fonts = self.selectedFonts, backgrounds = self.selectedBackgrounds
        
        let startDate = Date()
        let charset = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
        
        self.worker = TrainingWorker(fonts: fonts, backgrounds: backgrounds, charset: charset, maxTextLength: TrainingParameters.MaxTrainingTextLength)
        
        self.worker!.progress = { [weak self] (accuracy) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.accuracyLabel.stringValue = String(format: "%.04f%%", accuracy * 100)
            }
        }
        
        self.worker!.finished = { [weak self] (ffnn) in
            print("worker finished")
            guard let strongSelf = self else {
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH.mm.ss"
            
            var outputFile = URL(fileURLWithPath: strongSelf.outputDirectory!, isDirectory: true)
            outputFile.appendPathComponent("VinnyOCR_\(formatter.string(from: Date())).ocr", isDirectory: false)
            
            let model = VinnyOCR(charset: charset, ffnn: ffnn)!
            let data = try! JSONEncoder().encode(model)
            try! data.write(to: outputFile, options: [.atomic])
            
            print("finished training in \(Date().timeIntervalSince(startDate)) seconds")
            
            strongSelf.worker = nil
            strongSelf.updateComponentsWhileWorking()
        }
        
        print("starting worker")
        self.worker!.startTraining()
        self.updateComponentsWhileWorking()
    }
    
    private func stopMakingData() {
        self.makeTrainingDataButton.isEnabled = false
        self.makeTrainingDataButton.title = "Stopping..."
        self.worker?.stopTraining()
    }
    
    private func updateComponentsWhileConfiguring() {
        self.makeTrainingDataButton.isEnabled = (self.outputDirectory != nil) && (!self.selectedBackgrounds.isEmpty) && (!self.selectedFonts.isEmpty)
    }
    
    private func updateComponentsWhileWorking() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync(execute: self.updateComponentsWhileWorking)
            return
        }
        
        let isWorking = self.isWorking
        self.updateableElements.forEach({ $0?.isEnabled = !isWorking })
        
        self.makeTrainingDataButton.isEnabled = true
        self.makeTrainingDataButton.title = (isWorking ? "Stop Training" : "Start Training")
    }
}

extension TrainingViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.fonts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }
        
        let fontName = self.fonts[row]
        let font = NSFont(name: fontName, size: 0.0)!
        
        if identifier.rawValue == "0" {
            // Font column
            
            let cellId = NSUserInterfaceItemIdentifier(rawValue: "fontCell")
            let cell = tableView.makeView(withIdentifier: cellId, owner: self) as! NSTableCellView
            
            cell.textField?.stringValue = font.displayName!
            return cell
        } else {
            // Check column
            
            let cellId = NSUserInterfaceItemIdentifier(rawValue: "shouldTrainCell")
            let cell = tableView.makeView(withIdentifier: cellId, owner: self) as! ShouldTrainTableViewCell
            
            cell.checkButton.identifier = NSUserInterfaceItemIdentifier(fontName)
            cell.checkButton.integerValue = (self.selectedFonts.contains(fontName) ? 1 : 0)
            
            return cell
        }
    }
}
