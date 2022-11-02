// http://blog.human-friendly.com/drawing-images-from-pixel-data-in-swift
// https://github.com/FlexMonkey/MetalReactionDiffusion/blob/1ea9aa4a841d20e0b247505fdf716cd5fe1a01fd/MetalReactionDiffusion/ViewController.swift

import CoreGraphics
import UIKit

public struct PixelData {
    var a:UInt8 = 255
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.toRaw())
//
//public func imageFromARGB32Bitmap(pixels:[PixelData], width:UInt, height:UInt)->UIImage {
//    let bitsPerComponent:UInt = 8
//    let bitsPerPixel:UInt = 32
//
//    assert(pixels.count == Int(width * height))
//
//    var data = pixels // Copy to mutable []
//    let providerRef = CGDataProviderCreateWithCFData(
//            NSData(bytes: &data, length: data.count * sizeof(PixelData))
//        )
//
//    let cgim = CGImageCreate(
//            width,
//            height,
//            bitsPerComponent,
//            bitsPerPixel,
//            width * UInt(sizeof(PixelData)),
//            rgbColorSpace,
//            bitmapInfo,
//            providerRef,
//            nil,
//            true,
//            kCGRenderingIntentDefault
//        )
//    return UIImage(CGImage: cgim)
//}

extension UIImage {
    convenience init(texture: MTLTexture) {
        if texture.height > 1 {
            // rgba color texture
            let bitsPerComponent = 8
            let bitsPerPixel = 32
            let bytesPerRow = texture.width * 4
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo:CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
                
            let cgim = CGImage.init(width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: UIImage.dataProviderRefFrom(texture: texture), decode: nil, shouldInterpolate: false, intent: .defaultIntent)

            self.init(cgImage: cgim!)
        } else {
            // depth texture
            let bitsPerComponent = 16
            let bitsPerPixel = 16
            let bytesPerRow = texture.width * 2
            let grayColorSpace = CGColorSpaceCreateDeviceGray()
            let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
                
            let cgim = CGImage.init(width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: grayColorSpace, bitmapInfo: bitmapInfo, provider: UIImage.dataProviderRefFrom(texture: texture), decode: nil, shouldInterpolate: false, intent: .defaultIntent)

            self.init(cgImage: cgim!)
        }
    }
  
    static func dataProviderRefFrom(texture: MTLTexture) -> CGDataProvider {
        let region = MTLRegionMake2D(0, 0, Int(texture.width), Int(texture.height))
        let pixelCount: Int = texture.width * texture.height
        var imageBytes = [UInt8](repeating: 0, count: pixelCount * 4)
        texture.getBytes(&imageBytes, bytesPerRow: 4 * texture.width, from: region, mipmapLevel: 0)
        let providerRef = CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * 4 * MemoryLayout<UInt8>.size))
        return providerRef!
    }
}
