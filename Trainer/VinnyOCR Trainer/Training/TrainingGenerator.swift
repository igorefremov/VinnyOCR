//
//  TrainingGenerator.swift
//  VinnyOCR Trainer
//
//  Created by Igor Efremov on 1/11/19.
//

import Cocoa

class TrainingGenerator {
    private let fonts: [String]
    private let backgrounds: [NSImage]
    
    private var randomBackground: NSImage {
        return self.backgrounds[Int.random(in: (0..<self.backgrounds.count))]
    }
    
    private var randomFont: NSFont {
        let name = self.fonts[Int.random(in: (0..<self.fonts.count))]
        return NSFont(name: name, size: 30.0 + CGFloat.random(absMax: 10.0))!
    }
    
    private var randomFontAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.center
        
        let randomColor: () -> CGFloat = { 0.92 + CGFloat.random(absMax: 0.08) }
        
        let red = randomColor(), green = randomColor(), blue = randomColor()
        let alpha = 0.8 + CGFloat.random(absMax: 0.2)
        
        return [
            .font: self.randomFont,
            .kern: CGFloat(8) as NSObject,
            .foregroundColor: NSColor(red: red, green: green, blue: blue, alpha: alpha),
            .paragraphStyle: paragraphStyle
        ]
    }
    
    init(fonts: [String], backgrounds: [NSImage]) {
        self.fonts = fonts
        self.backgrounds = backgrounds
    }
    
    func generateImage(withTextLength textLength: Int, withCharset charset: String) -> (image: NSImage, text: String) {
        let text = String.random(ofLength: 17, fromCharset: charset)
        let background = self.randomBackground
        
        let fontAttributes = self.randomFontAttributes
        let textSize = NSString(string: text).size(withAttributes: fontAttributes)
        
        var drawSize = background.size
        var mulRatio: CGFloat = 1.0
        
        if drawSize.width < textSize.width * 1.1 {
            mulRatio *= (textSize.width * 1.1) / drawSize.width
        }
        if drawSize.height < (textSize.height * 1.1) {
            mulRatio *= (textSize.height * 1.1) / drawSize.height
        }
        
        drawSize.width *= mulRatio
        drawSize.height *= mulRatio
        
        let textX = (drawSize.width - textSize.width) / 2.0
        let textY = (drawSize.height - textSize.height) / 2.0
        
        let ret = NSImage(size: drawSize)
        ret.lockFocus()
        background.draw(in: CGRect(origin: .zero, size: drawSize))
        NSString(string: text).draw(at: CGPoint(x: textX, y: textY), withAttributes: fontAttributes)
        ret.unlockFocus()
        
        return (ret, text)
    }
}
