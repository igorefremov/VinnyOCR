//
//  TrainingWorker.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 2/1/19.
//

import Cocoa
import VinnyOCR

private typealias NetworkInputs = (blobs: [[Float]], answers: [[Float]])

class TrainingWorker {
    private let generator: TrainingGenerator
    
    private let charset: String
    private let length: Int
    
    private var ffnn: FFNN
    
    private var running = false
    private var stop = false
    
    var progress: ((Float) -> Void)?
    var finished: ((FFNN) -> Void)?
    
    init(fonts: [String], backgrounds: [NSImage], charset: String, maxTextLength: Int) {
        self.generator = TrainingGenerator(fonts: fonts, backgrounds: backgrounds)
        self.charset = charset
        self.length = maxTextLength
        
        // 321 inputs are used because the images are scaled to 16x20, stuffed into an array, and then the aspect ratio of the non-scaled image
        // is appended to the end of the array. (16 * 20) + 1 = 321
        self.ffnn = FFNN(inputs: 321, hidden: TrainingParameters.HiddenNodeCount, outputs: charset.count,
                         learningRate: TrainingParameters.LearningRate, momentum: TrainingParameters.Momentum,
                         weights: nil, activationFunction: .Sigmoid, errorFunction: .crossEntropy(average: false))
    }
    
    func startTraining() {
        guard !self.running else {
            return
        }
        
        self.running = true
        self.stop = false
        
        Thread(block: self.trainNetwork).start()
    }
    
    func stopTraining() {
        self.stop = true
    }
    
    private func finish() {
        self.running = false
        self.finished?(self.ffnn)
    }
    
    private func makeNetworkInputs(inputCount: Int, testCount: Int) -> (inputs: NetworkInputs, tests: NetworkInputs) {
        var inputs = NetworkInputs([[Float]](), [[Float]]())
        var tests = NetworkInputs([[Float]](), [[Float]]())
        
        // Make input data
        for _ in (0..<inputCount) {
            let data = self.makeTrainingData()
            inputs.blobs.append(contentsOf: data.blobs)
            inputs.answers.append(contentsOf: data.answers)
        }
        
        // Make test data
        for _ in (0..<testCount) {
            let data = self.makeTrainingData()
            tests.blobs.append(contentsOf: data.blobs)
            tests.answers.append(contentsOf: data.answers)
        }
        
        return (inputs, tests)
    }
    
    private func makeTrainingData() -> NetworkInputs {
        let lock = NSLock()
        
        var data = [[Float]]()
        var answers = [[Float]]()
        
        var madeData = false
        repeat {
            let length = 3 + Int(arc4random_uniform(UInt32(self.length) - 3))
            
            let trainingData = self.generator.generateImage(withTextLength: length, withCharset: self.charset)
            let generatedImage = trainingData.image.preprocess()
            let generatedText = trainingData.text
            
            lock.lock()
            generatedImage.findCharacters(completion: { (foundChars) in
                if let foundChars = foundChars, foundChars.count == generatedText.count {
                    for index in (0..<foundChars.count) {
                        let char = foundChars[index]
                        let generatedChar = generatedText[index]
                        
                        var answer = [Float](repeating: 0.0, count: self.charset.count)
                        answer[self.charset.firstIndex(of: generatedChar)!] = 1.0
                        
                        data.append(char.blob)
                        answers.append(answer)
                    }
                    
                    madeData = true
                }
                lock.unlock()
            })
            
            // Dirty little hack to make an async function (image.findCharacters) appear synchronous
            lock.cycle()
        } while !madeData
        
        return (data, answers)
    }
    
    private func trainNetwork() {
        let inputs = self.makeNetworkInputs(inputCount: TrainingParameters.InputCount, testCount: TrainingParameters.TestCount)
        
        var accuracyTests = NetworkInputs([[Float]](), [[Float]]())
        for _ in (0..<50) {
            let data = self.makeTrainingData()
            accuracyTests.blobs.append(contentsOf: data.blobs)
            accuracyTests.answers.append(contentsOf: data.answers)
        }
        
        do {
            _ = try self.ffnn.train(inputs: inputs.inputs.blobs, answers: inputs.inputs.answers, testInputs: inputs.tests.blobs, testAnswers: inputs.tests.answers, errorThreshold: 05, shouldContinue: { (error) -> (Bool, NetworkInputs?) in
                return (self.running && (!self.stop), accuracyTests)
            }, accuracy: self.progress)
        } catch {
            print("exception encountered while training: \(error)")
        }
        
        self.finish()
    }
}
