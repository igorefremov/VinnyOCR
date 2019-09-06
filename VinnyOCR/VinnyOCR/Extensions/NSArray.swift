//
//  NSArray.swift
//  VinnyOCR
//
//  Created by Igor Efremov on 1/14/19.
//

import Foundation

internal extension Array where Element: Collection, Element.Index == Int, Element.Iterator.Element: Any {
    func transpose() -> [[Element.Iterator.Element]] {
        if self.isEmpty { return [] }
        
        typealias InnerElement = Element.Iterator.Element
        
        let count = self[0].count
        var out = [[InnerElement]](repeating: [InnerElement](), count: count)
        for outer in self {
            for (index, inner) in outer.enumerated() {
                out[index].append(inner)
            }
        }
        return out
    }
}
