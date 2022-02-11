//
//  Extension-HT.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

extension UIColor {
    class func ColorFromRGB(_ rgb: UInt) -> UIColor {
        return UIColor(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgb & 0x0000FF) / 255.0, alpha: 1.0)
    }
}

extension UIImage {
    func scaledImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()?.data.flatMap(UIImage.init)
    }
    
    private var data: Data? {
        return self.pngData() ?? self.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - 通知Name
extension Notification.Name {
    public struct Language {
        public static let refreshText = Notification.Name(rawValue: "refreshText")
        public static let refreshOcr = Notification.Name(rawValue: "refreshOcr")
    }
    
    public struct Remote {
        public static let config = Notification.Name(rawValue: "remoteConfig")
    }
    
    public struct AD {
        public static let transNative = Notification.Name(rawValue: "transNative")
        public static let rootHomeNative = Notification.Name(rawValue: "rootHomeNative")
        public static let vHomeNative = Notification.Name(rawValue: "vHomeNative")
    }
}
