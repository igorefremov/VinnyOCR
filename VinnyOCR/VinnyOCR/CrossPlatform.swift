//
//  CrossPlatform.swift
//  VinnyOCR
//
//  Created by Igor Efremov on 1/14/19.
//

#if os(iOS)
import UIKit
public typealias OCRImage = UIImage
#else
import Cocoa
public typealias OCRImage = NSImage
#endif
