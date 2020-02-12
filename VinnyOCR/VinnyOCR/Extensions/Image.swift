//
//  Image.swift
//  VinnyOCR
//
//  Created by Igor Efremov on 1/11/19.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import Accelerate
import Vision

private typealias ProcessingBuffer = (buffer: vImage_Buffer, format: vImage_CGImageFormat)

private let imageContext = CIContext()

private extension vImage_Buffer {
    func releaseResources() {
        if #available(macOS 10.15, iOS 13.0, *) {
            self.free()
        } else {
            Darwin.free(self.data)
        }
    }
}

private extension vImage_Buffer {
    var dataBuffer: [UInt8] {
        let pointer = self.data!.assumingMemoryBound(to: UInt8.self)
        let bufferPointer = UnsafeBufferPointer(start: pointer, count: Int(self.width * self.height))
        return [UInt8](bufferPointer)
    }
    
    static func argb(_ data: inout ProcessingBuffer) -> ProcessingBuffer {
        return vImage_Buffer.argb(sourceBuffer: &data.buffer, sourceFormat: &data.format)
    }
    
    static func argb(sourceBuffer: inout vImage_Buffer, sourceFormat: inout vImage_CGImageFormat) -> ProcessingBuffer {
        var buffer = vImage_Buffer()
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32,
                                          colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                          version: 0, decode: nil, renderingIntent: .defaultIntent)
        
        vImageBuffer_Init(&buffer, sourceBuffer.height, sourceBuffer.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
        
        let converter = vImageConverter_CreateWithCGImageFormat(&sourceFormat, &format, nil, vImage_Flags(kvImageNoFlags), nil)!.takeRetainedValue()
        vImageConvert_AnyToAny(converter, &sourceBuffer, &buffer, nil, vImage_Flags(kvImageNoFlags))
        sourceBuffer.releaseResources()
        
        return (buffer, format)
    }
    
    static func monochromatic(_ data: inout ProcessingBuffer) -> ProcessingBuffer {
        return vImage_Buffer.monochromatic(sourceBuffer: &data.buffer, sourceFormat: &data.format)
    }
    
    static func monochromatic(sourceBuffer: inout vImage_Buffer, sourceFormat: inout vImage_CGImageFormat) -> ProcessingBuffer {
        let divisor: Int32 = 0x1000
        let fDivisor = Float(divisor)
        var coefficientsMatrix = [Int16(0.2126 * fDivisor), Int16(0.7152 * fDivisor), Int16(0.0722 * fDivisor), 0]
        
        var preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        
        var buffer = vImage_Buffer()
        let format = vImage_CGImageFormat(bitsPerComponent: 8,
                                          bitsPerPixel: 8,
                                          colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceGray()),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                          version: 0, decode: nil, renderingIntent: .defaultIntent)
        
        vImageBuffer_Init(&buffer, sourceBuffer.height, sourceBuffer.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
        vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer, &buffer, &coefficientsMatrix, divisor, &preBias, postBias, vImage_Flags(kvImageNoFlags))
        sourceBuffer.releaseResources()
        
        var oneBitBuffer = vImage_Buffer()
        let oneBitFormat = vImage_CGImageFormat(bitsPerComponent: 1,
                                                bitsPerPixel: 1,
                                                colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceGray()),
                                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                                version: 0, decode: nil, renderingIntent: .defaultIntent)
        
        vImageBuffer_Init(&oneBitBuffer, buffer.height, buffer.width, 1, vImage_Flags(kvImageNoFlags))
        vImageConvert_Planar8toPlanar1(&buffer, &oneBitBuffer, nil, Int32(kvImageConvert_DitherNone), vImage_Flags(kvImageNoFlags))
        buffer.releaseResources()
        
        return (oneBitBuffer, oneBitFormat)
    }
    
    static func scale(_ data: inout ProcessingBuffer) -> ProcessingBuffer {
        return vImage_Buffer.scale(sourceBuffer: &data.buffer, sourceFormat: &data.format, width: 16, height: 20)
    }
    
    static func scale(sourceBuffer: inout vImage_Buffer, sourceFormat: inout vImage_CGImageFormat, width: UInt, height: UInt) -> ProcessingBuffer {
        var buffer = vImage_Buffer()
        vImageBuffer_Init(&buffer, height, width, sourceFormat.bitsPerPixel, vImage_Flags(kvImageNoFlags))
        vImageScale_Planar8(&sourceBuffer, &buffer, nil, vImage_Flags(kvImageNoFlags))
        sourceBuffer.releaseResources()
        
        return (buffer, sourceFormat)
    }
}

private extension CGImage {
    var imageBuffer: ProcessingBuffer {
        var buffer = vImage_Buffer()
        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(self.bitsPerComponent),
                                          bitsPerPixel: UInt32(self.bitsPerPixel),
                                          colorSpace: Unmanaged.passRetained(self.colorSpace!),
                                          bitmapInfo: self.bitmapInfo,
                                          version: 0, decode: nil, renderingIntent: self.renderingIntent)
        
        vImageBuffer_InitWithCGImage(&buffer, &format, nil, self, vImage_Flags(kvImageNoFlags))
        return (buffer, format)
    }
}

private extension OCRImage {
    #if !os(iOS)
    var cgImage: CGImage? { return self.cgImage(forProposedRect: nil, context: nil, hints: nil) }
    #endif
    
    var imageBuffer: ProcessingBuffer { return self.cgImage!.imageBuffer }
    
    convenience init(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) {
        let result = vImageCreateCGImageFromBuffer(&buffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)!
        let cgImage = result.takeRetainedValue()
        buffer.releaseResources()
        
        #if os(iOS)
        self.init(cgImage: cgImage)
        #else
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
    
    func adjustColors() -> OCRImage {
        #if os(iOS)
        let cgImage = self.cgImage!
        #else
        let cgImage = NSBitmapImageRep(data: self.tiffRepresentation!)!.cgImage!
        #endif
        
        let filter = CIFilter(name: "CIColorControls")!
        let ciImage = CIImage(cgImage: cgImage)
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        filter.setValue(1.45, forKey: kCIInputContrastKey)
        
        let outputCIImage = filter.outputImage!
        let outputCGImage = imageContext.createCGImage(outputCIImage, from: outputCIImage.extent)!

        #if os(iOS)
        return OCRImage(cgImage: outputCGImage)
        #else
        return OCRImage(cgImage: outputCGImage, size: self.size)
        #endif
    }
}

public extension OCRImage {
    final func findCharacters(completion: @escaping ([(blob: [Float], location: CGRect)]?) -> Void) {
        #if os(iOS)
        let cgImage = self.cgImage!
        #else
        let cgImage = NSBitmapImageRep(data: self.tiffRepresentation!)!.cgImage!
        #endif
        
        let width = self.size.width, height = self.size.height
        
        let request = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else {
                completion(nil)
                return
            }
            
            var locations = [CGRect]()
            var averageBoxHeight: CGFloat = 0.0
            
            for observation in observations {
                let boxes = observation.characterBoxes!
                for box in boxes {
                    // min/max X/Y are returned on a scale from 0.0 to 1.0
                    let minX = min(box.bottomLeft.x, box.topLeft.x) * width, maxX = max(box.bottomRight.x, box.topRight.x) * width
                    let minY = min(box.bottomLeft.y, box.bottomRight.y) * height, maxY = max(box.topLeft.y, box.topRight.y) * height
                    let rect = CGRect(x: minX, y: minY, width: (maxX - minX), height: (maxY - minY))
                        
                    locations.append(rect)
                    averageBoxHeight += rect.size.height
                }
            }
            averageBoxHeight /= CGFloat(locations.count)
            
            let newRowThreshold = averageBoxHeight * 0.7
            locations.sort(by: { (rect1, rect2) -> Bool in
                let verticalDifference = abs(rect1.origin.y - rect2.origin.y)
                if verticalDifference > newRowThreshold {
                    return rect1.origin.y < rect2.origin.y
                } else {
                    return rect1.origin.x < rect1.origin.x
                }
            })
            
            var result = [([Float], CGRect)]()
            for location in locations {
                if let croppedCGImage = cgImage.cropping(to: location) {
                    var data = croppedCGImage.imageBuffer
                    let aspectRatio = Float(croppedCGImage.width) / Float(croppedCGImage.height)
                
                    data = vImage_Buffer.scale(&data)
                    
                    var dataBuffer = data.buffer.dataBuffer.map({ ($0 > 126 ? 0.0 : 1.0) as Float })
                    dataBuffer.append(aspectRatio)
                    
                    result.append((dataBuffer, location))
                    data.buffer.releaseResources()
                }
            }
            
            completion(result)
        }
        
        request.reportCharacterBoxes = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
    
    final func preprocess() -> OCRImage {
        var data = self.adjustColors().imageBuffer
        data = vImage_Buffer.argb(&data)
        data = vImage_Buffer.monochromatic(&data)
        return OCRImage(buffer: &data.buffer, format: &data.format)
    }
}
