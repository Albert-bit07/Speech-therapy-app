import Foundation

@main
struct FloatingGeometryTests {
    static func main() {
        for length: CGFloat in [0, 1, 50, 99, 100, 150, 199, 200, 800] {
            for inset: CGFloat in [0, 50, 100] {
                let range = FloatingGeometry.insetRange(length: length, inset: inset)
                precondition(range.lowerBound >= 0 && range.upperBound <= length)
                for _ in 0..<100 {
                    let position = CGFloat.random(in: range)
                    precondition(position >= 0 && position <= length)
                }
            }
        }
        precondition(FloatingGeometry.insetRange(length: 50, inset: 100) == 25...25)
        precondition(FloatingGeometry.insetRange(length: 800, inset: 50) == 50...750)
        for length: CGFloat in [-1, .infinity, .nan] {
            precondition(FloatingGeometry.insetRange(length: length, inset: 50) == 0...0)
        }
        print("Passed compact, zero-size and invalid floating geometry regressions")
    }
}
