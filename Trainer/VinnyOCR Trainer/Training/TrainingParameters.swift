//
//  TrainingParameters.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 9/4/19.
//

import Foundation

struct TrainingParameters {
    static let ExpectedTextLength           = 17
    
    static let HiddenNodeCount              = 100
    static let LearningRate: Float          = 0.35
    static let Momentum: Float              = 0.7
    
    static let InputCount                   = 200
    static let TestCount                    = 40
    
    static let ErrorThreshold: Float        = 0.5
}
