import UIKit

enum ImageCompression {
    /// Compress meal photos before vision API calls (adapted from NutriScope).
    static func compressForAnalysis(_ data: Data, maxDimension: CGFloat = 1_920, quality: CGFloat = 0.82, maxBytes: Int = 500_000) -> Data {
        guard data.count > maxBytes, let image = UIImage(data: data) else { return data }

        let resized = resize(image, maxDimension: maxDimension)
        var compression = quality
        var output = resized.jpegData(compressionQuality: compression) ?? data

        while output.count > maxBytes && compression > 0.45 {
            compression -= 0.08
            if let next = resized.jpegData(compressionQuality: compression) {
                output = next
            } else {
                break
            }
        }

        return output
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
