//
//  VinnyOCR.swift
//  VinnyOCR
//
//  Created by Igor Efremov on 1/14/19.
//

import Foundation

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (lhs?, rhs?):      return lhs < rhs
    case (nil, _?):             return true
    default:                    return false
    }
}

private func >= <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    return !(lhs < rhs)
}

public final class VinnyOCR: Codable {
    private enum CodingKeys: String, CodingKey {
        case charset, ffnn
    }
    
    private static let confidenceThreshold: Float = 0.1
    
    private let charset: String
    private var ffnn: FFNN

    private let processingLock = NSLock()
    
    public init?(charset: String, ffnn: FFNN) {
        guard !charset.isEmpty else {
            return nil
        }
        
        self.charset = charset
        self.ffnn = ffnn
    }
    
    public init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let model = try? JSONDecoder().decode(VinnyOCR.self, from: data) else {
            return nil
        }
        
        self.charset = model.charset
        self.ffnn = model.ffnn
    }

    public final func recognize(_ image: OCRImage, completion: @escaping (String) -> Void) {
        guard self.processingLock.try() else {
            return
        }
        
        let preprocessedImage = image.preprocess()
        preprocessedImage.findCharacters { (chars) in
            guard let chars = chars else {
                completion("")
                self.processingLock.unlock()
                return
            }
            
            var result = ""
            for char in chars {
                guard let answer = try? self.ffnn.update(inputs: char.blob), answer.max() >= VinnyOCR.confidenceThreshold else {
                    continue
                }
                
                let largestAnswer = answer.enumerated().sorted(by: { $0.element > $1.element }).first!
                let mappedChar = self.charset[self.charset.index(self.charset.startIndex, offsetBy: largestAnswer.offset)]
                result += String(mappedChar)
            }
            
            completion(result)
            self.processingLock.unlock()
        }
    }
}
