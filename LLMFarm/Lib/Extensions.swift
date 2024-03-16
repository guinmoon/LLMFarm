//
//  Extensions.swift
//  LLMFarm
//
//  Created by guinmoon on 04.12.2023.
//

import Foundation


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
import Accelerate

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
