//
//  Extensions.swift
//  LLMFarm
//
//  Created by guinmoon on 04.12.2023.
//

import Foundation
import Accelerate

public enum Field: Int, CaseIterable {
        case msg
}

extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}

public func run_after_delay(delay: Int, function: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
        function()
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}


#if os(macOS)
import Cocoa


// Step 1: Typealias UIImage to NSImage
typealias UIImage = NSImage

// Step 2: You might want to add these APIs that UIImage has but NSImage doesn't.
extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)

        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }

    convenience init?(named name: String) {
        self.init(named: Name(name))
    }
}

extension NSImage {

    /// The height of the image.
    var height: CGFloat {
        return size.height
    }

    /// The width of the image.
    var width: CGFloat {
        return size.width
    }

    /// A PNG representation of the image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }

        return nil
    }

    // MARK: Resizing

    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
    func resize(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }

    /// Copy the image and resize it to the supplied size, while maintaining it's
    /// original aspect ratio.
    ///
    /// - Parameter size: The target size of the image.
    /// - Returns: The resized image.
    func resizeMaintainingAspectRatio(withSize targetSize: NSSize) -> NSImage? {
        let newSize: NSSize
        let widthRatio  = targetSize.width / self.width
        let heightRatio = targetSize.height / self.height

        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio),
                             height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio),
                             height: floor(self.height * heightRatio))
        }
        return self.resize(withSize: newSize)
    }

    // MARK: Cropping

    /// Resize the image, to nearly fit the supplied cropping size
    /// and return a cropped copy the image.
    ///
    /// - Parameter size: The size of the new image.
    /// - Returns: The cropped image.
    func crop(toSize targetSize: NSSize) -> NSImage? {
        guard let resizedImage = self.resizeMaintainingAspectRatio(withSize: targetSize) else {
            return nil
        }
        let x     = floor((resizedImage.width - targetSize.width) / 2)
        let y     = floor((resizedImage.height - targetSize.height) / 2)
        let frame = NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height)

        guard let representation = resizedImage.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }

        let image = NSImage(size: targetSize,
                            flipped: false,
                            drawingHandler: { (destinationRect: NSRect) -> Bool in
            return representation.draw(in: destinationRect)
        })

        return image
    }

    // MARK: Saving

    /// Save the images PNG representation the the supplied file URL:
    ///
    /// - Parameter url: The file URL to save the png file to.
    /// - Throws: An unwrappingPNGRepresentationFailed when the image has no png representation.
    func savePngTo(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        } else {
            throw NSImageExtensionError.unwrappingPNGRepresentationFailed
        }
    }
}


/// Exceptions for the image extension class.
///
/// - creatingPngRepresentationFailed: Is thrown when the creation of the png representation failed.
enum NSImageExtensionError: Error {
    case unwrappingPNGRepresentationFailed
}

#endif







#if os(iOS)
import UIKit

extension UIImage {
    
    func normalizedImage() -> UIImage?
    {        
        if self.imageOrientation == .up
        {
            return self
        }
        else
        {
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
            defer
            {
                UIGraphicsEndImageContext()
            }

            self.draw(in: CGRect(origin: .zero, size: self.size))

            return UIGraphicsGetImageFromCurrentImageContext()
        }
    }
    
    var fixedOrientation: UIImage {
        guard imageOrientation != .up else { return self }
        
        var transform: CGAffineTransform = .identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform
                .translatedBy(x: size.width, y: size.height).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform
                .translatedBy(x: size.width, y: 0).rotated(by: .pi)
        case .right, .rightMirrored:
            transform = transform
                .translatedBy(x: 0, y: size.height).rotated(by: -.pi/2)
        case .upMirrored:
            transform = transform
                .translatedBy(x: size.width, y: 0).scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard
            let cgImage = cgImage,
            let colorSpace = cgImage.colorSpace,
            let context = CGContext(
                data: nil, width: Int(size.width), height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue
            )
        else { return self }
        context.concatenate(transform)
        
        var rect: CGRect
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            rect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        default:
            rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        
        context.draw(cgImage, in: rect)
        return context.makeImage().map { UIImage(cgImage: $0) } ?? self
    }
}

//#endif

extension UIImage {

    public enum ResizeFramework {
        case accelerate
    }

    /// Resize image with ScaleAspectFit mode and given size.
    ///
    /// - Parameter dimension: width or length of the image output.
    /// - Parameter resizeFramework: Technique for image resizing: UIKit / CoreImage / CoreGraphics / ImageIO / Accelerate.
    /// - Returns: Resized image.

    func resizeWithScaleAspectFitMode(to dimension: CGFloat, resizeFramework: ResizeFramework = .accelerate) -> UIImage? {

        if max(size.width, size.height) <= dimension { return self }

        var newSize: CGSize!
        let aspectRatio = size.width/size.height

        if aspectRatio > 1 {
            // Landscape image
            newSize = CGSize(width: dimension, height: dimension / aspectRatio)
        } else {
            // Portrait image
            newSize = CGSize(width: dimension * aspectRatio, height: dimension)
        }

        return resize(to: newSize, with: resizeFramework)
    }

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Parameter resizeFramework: Technique for image resizing: UIKit / CoreImage / CoreGraphics / ImageIO / Accelerate.
    /// - Returns: Resized image.
    public func resize(to newSize: CGSize, with resizeFramework: ResizeFramework = .accelerate) -> UIImage? {
        switch resizeFramework {
//            case .uikit: return resizeWithUIKit(to: newSize)
//            case .coreGraphics: return resizeWithCoreGraphics(to: newSize)
//            case .coreImage: return resizeWithCoreImage(to: newSize)
//            case .imageIO: return resizeWithImageIO(to: newSize)
            case .accelerate: return resizeWithAccelerate(to: newSize)
        }
    }

//    // MARK: - UIKit
//
//    /// Resize image from given size.
//    ///
//    /// - Parameter newSize: Size of the image output.
//    /// - Returns: Resized image.
//    private func resizeWithUIKit(to newSize: CGSize) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
//        self.draw(in: CGRect(origin: .zero, size: newSize))
//        defer { UIGraphicsEndImageContext() }
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
//
//    // MARK: - CoreImage
//
//    /// Resize CI image from given size.
//    ///
//    /// - Parameter newSize: Size of the image output.
//    /// - Returns: Resized image.
//    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
//    private func resizeWithCoreImage(to newSize: CGSize) -> UIImage? {
//        guard let cgImage = cgImage, let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
//
//        let ciImage = CIImage(cgImage: cgImage)
//        let scale = (Double)(newSize.width) / (Double)(ciImage.extent.size.width)
//
//        filter.setValue(ciImage, forKey: kCIInputImageKey)
//        filter.setValue(NSNumber(value:scale), forKey: kCIInputScaleKey)
//        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
//        guard let outputImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else { return nil }
//        let context = CIContext(options: [.useSoftwareRenderer: false])
//        guard let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
//        return UIImage(cgImage: resultCGImage)
//    }
//
//    // MARK: - CoreGraphics
//
//    /// Resize image from given size.
//    ///
//    /// - Parameter newSize: Size of the image output.
//    /// - Returns: Resized image.
//    private func resizeWithCoreGraphics(to newSize: CGSize) -> UIImage? {
//        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return nil }
//
//        let width = Int(newSize.width)
//        let height = Int(newSize.height)
//        let bitsPerComponent = cgImage.bitsPerComponent
//        let bytesPerRow = cgImage.bytesPerRow
//        let bitmapInfo = cgImage.bitmapInfo
//
//        guard let context = CGContext(data: nil, width: width, height: height,
//                                      bitsPerComponent: bitsPerComponent,
//                                      bytesPerRow: bytesPerRow, space: colorSpace,
//                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
//        context.interpolationQuality = .high
//        let rect = CGRect(origin: CGPoint.zero, size: newSize)
//        context.draw(cgImage, in: rect)
//
//        return context.makeImage().flatMap { UIImage(cgImage: $0) }
//    }
//
//    // MARK: - ImageIO
//
//    /// Resize image from given size.
//    ///
//    /// - Parameter newSize: Size of the image output.
//    /// - Returns: Resized image.
//    private func resizeWithImageIO(to newSize: CGSize) -> UIImage? {
//        var resultImage = self
//
//        guard let data = jpegData(compressionQuality: 1.0) else { return resultImage }
//        let imageCFData = NSData(data: data) as CFData
//        let options = [
//            kCGImageSourceCreateThumbnailWithTransform: true,
//            kCGImageSourceCreateThumbnailFromImageAlways: true,
//            kCGImageSourceThumbnailMaxPixelSize: max(newSize.width, newSize.height)
//            ] as CFDictionary
//        guard   let source = CGImageSourceCreateWithData(imageCFData, nil),
//                let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return resultImage }
//        resultImage = UIImage(cgImage: imageReference)
//
//        return resultImage
//    }

    // MARK: - Accelerate

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    private func resizeWithAccelerate(to newSize: CGSize) -> UIImage? {
        var resultImage = self

        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return nil }

        // create a source buffer
        var format = vImage_CGImageFormat(bitsPerComponent: numericCast(cgImage.bitsPerComponent),
                                          bitsPerPixel: numericCast(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passUnretained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .absoluteColorimetric)
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.data.deallocate()
        }

        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return resultImage }

        // create a destination buffer
        let destWidth = Int(newSize.width)
        let destHeight = Int(newSize.height)
        let bytesPerPixel = cgImage.bitsPerPixel
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return resultImage }

        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return resultImage }

        // create a UIImage
        if let scaledImage = destCGImage.flatMap({ UIImage(cgImage: $0) }) {
            resultImage = scaledImage
        }

        return resultImage
    }
}

 #endif



extension UUID {
    // UUID is 128-bit, we need two 64-bit values to represent it
    var integers: (Int64, Int64) {
        var a: UInt64 = 0
        a |= UInt64(self.uuid.0)
        a |= UInt64(self.uuid.1) << 8
        a |= UInt64(self.uuid.2) << (8 * 2)
        a |= UInt64(self.uuid.3) << (8 * 3)
        a |= UInt64(self.uuid.4) << (8 * 4)
        a |= UInt64(self.uuid.5) << (8 * 5)
        a |= UInt64(self.uuid.6) << (8 * 6)
        a |= UInt64(self.uuid.7) << (8 * 7)
        
        var b: UInt64 = 0
        b |= UInt64(self.uuid.8)
        b |= UInt64(self.uuid.9) << 8
        b |= UInt64(self.uuid.10) << (8 * 2)
        b |= UInt64(self.uuid.11) << (8 * 3)
        b |= UInt64(self.uuid.12) << (8 * 4)
        b |= UInt64(self.uuid.13) << (8 * 5)
        b |= UInt64(self.uuid.14) << (8 * 6)
        b |= UInt64(self.uuid.15) << (8 * 7)
        
        return (Int64(bitPattern: a), Int64(bitPattern: b))
    }
    
    static func from(integers: (Int64, Int64)) -> UUID {
        let a = UInt64(bitPattern: integers.0)
        let b = UInt64(bitPattern: integers.1)
        return UUID(uuid: (
            UInt8(a & 0xFF),
            UInt8((a >> 8) & 0xFF),
            UInt8((a >> (8 * 2)) & 0xFF),
            UInt8((a >> (8 * 3)) & 0xFF),
            UInt8((a >> (8 * 4)) & 0xFF),
            UInt8((a >> (8 * 5)) & 0xFF),
            UInt8((a >> (8 * 6)) & 0xFF),
            UInt8((a >> (8 * 7)) & 0xFF),
            UInt8(b & 0xFF),
            UInt8((b >> 8) & 0xFF),
            UInt8((b >> (8 * 2)) & 0xFF),
            UInt8((b >> (8 * 3)) & 0xFF),
            UInt8((b >> (8 * 4)) & 0xFF),
            UInt8((b >> (8 * 5)) & 0xFF),
            UInt8((b >> (8 * 6)) & 0xFF),
            UInt8((b >> (8 * 7)) & 0xFF)
        ))
    }
    
    var data: Data {
        var data = Data(count: 16)
        // uuid is a tuple type which doesn't have dynamic subscript access...
        data[0] = self.uuid.0
        data[1] = self.uuid.1
        data[2] = self.uuid.2
        data[3] = self.uuid.3
        data[4] = self.uuid.4
        data[5] = self.uuid.5
        data[6] = self.uuid.6
        data[7] = self.uuid.7
        data[8] = self.uuid.8
        data[9] = self.uuid.9
        data[10] = self.uuid.10
        data[11] = self.uuid.11
        data[12] = self.uuid.12
        data[13] = self.uuid.13
        data[14] = self.uuid.14
        data[15] = self.uuid.15
        return data
    }
    
    static func from(data: Data?) -> UUID? {
        guard data?.count == MemoryLayout<uuid_t>.size else {
            return nil
        }
        return data?.withUnsafeBytes{
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                return nil
            }
            return NSUUID(uuidBytes: baseAddress) as UUID
        }
    }
}
