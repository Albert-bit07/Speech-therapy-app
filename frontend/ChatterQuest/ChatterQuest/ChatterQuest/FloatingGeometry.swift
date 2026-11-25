import Foundation

enum FloatingGeometry {
    static func insetRange(length: CGFloat, inset: CGFloat) -> ClosedRange<CGFloat> {
        guard length.isFinite, length > 0 else { return 0...0 }
        let padding = inset.isFinite ? min(max(0, inset), length / 2) : 0
        return padding...(length - padding)
    }
}
