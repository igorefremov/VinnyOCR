//
//  TrainingParameters.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 9/4/19.
//

import Foundation

struct TrainingParameters {
    static let MaxTrainingTextLength        = 17
    
    static let HiddenNodeCount              = 200
    static let LearningRate: Float          = 0.2
    static let Momentum: Float              = 0.35
    
    static let InputCount                   = 500
    static let TestCount                    = 100
    
    static let ErrorThreshold: Float        = 2.0
    static let MaximumTrainCallbackCount    = 320
}
