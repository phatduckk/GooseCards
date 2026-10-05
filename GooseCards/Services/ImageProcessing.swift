import UIKit
import ImageIO

enum ImageProcessing {
    /// Downsamples image data to at most `maxDimension` on its longest side,
    /// re-encoded as JPEG. Uses CGImageSource's thumbnail generation so the
    /// (potentially huge, multi-megapixel) original is never fully decoded
    /// into memory — critical for images pulled from the web/Photos, which
    /// can arrive at several thousand pixels per side and tens of MB.
    static func downsample(data: Data, maxDimension: CGFloat = 1200, compressionQuality: CGFloat = 0.7) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        return UIImage(cgImage: cgImage).jpegData(compressionQuality: compressionQuality)
    }
}
