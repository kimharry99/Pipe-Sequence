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
public struct cgimData {
    var bitsPerComponent: Int
    var bitsPerPixel: Int
    var bytePerPixel: Int { get { return bitsPerPixel / 8 } }
    var colorSpace: CGColorSpace
    var bitmapInfo: CGBitmapInfo
}

let rgbCGimData = cgimData(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(), bitmapInfo: [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)])
let depthCGimData = cgimData(bitsPerComponent: 16, bitsPerPixel: 16, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Little.rawValue | CGImageAlphaInfo.none.rawValue))

let cgImDataDict: [MTLPixelFormat:cgimData] = [.rgba8Unorm:rgbCGimData, .r16Uint:depthCGimData]

extension UIImage {
    convenience init(texture: MTLTexture) {
        let bitsPerComponent = cgImDataDict[texture.pixelFormat]!.bitsPerComponent
        let bitsPerPixel = cgImDataDict[texture.pixelFormat]!.bitsPerPixel
        let bytesPerRow = texture.width * cgImDataDict[texture.pixelFormat]!.bytePerPixel
        let colorSpace = cgImDataDict[texture.pixelFormat]!.colorSpace
        let bitmapInfo: CGBitmapInfo = cgImDataDict[texture.pixelFormat]!.bitmapInfo

        let cgim = CGImage.init(width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: UIImage.dataProviderRefFrom(texture: texture), decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        self.init(cgImage: cgim!)
    }
  
    static func dataProviderRefFrom(texture: MTLTexture) -> CGDataProvider {
        let region = MTLRegionMake2D(0, 0, Int(texture.width), Int(texture.height))
        let pixelCount: Int = texture.width * texture.height
        if texture.pixelFormat == .rgba8Unorm {
            var imageBytes = [UInt8](repeating: 0, count: pixelCount * 4)
            texture.getBytes(&imageBytes, bytesPerRow: 4 * texture.width, from: region, mipmapLevel: 0)
            let providerRef = CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * 4 * MemoryLayout<UInt8>.size))
            return providerRef!
        }
        else {
            var imageBytes = [UInt16](repeating: 0, count: pixelCount * 1)
            texture.getBytes(&imageBytes, bytesPerRow: 2 * texture.width, from: region, mipmapLevel: 0)
            let providerRef = CGDataProvider(data: NSData(bytes: &imageBytes, length: pixelCount * 1 * MemoryLayout<UInt16>.size))
            return providerRef!
        }
    }
}
