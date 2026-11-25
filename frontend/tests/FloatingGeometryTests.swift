import Foundation

@main
struct FloatingGeometryTests {
    static func main() {
        let lengths: [CGFloat] = [0, 1, 50, 99, 100, 150, 199, 200, 800]
        let insets: [CGFloat] = [0, 50, 100]
        for length in lengths {
            for inset in insets {
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
        let invalidLengths: [CGFloat] = [-1, .infinity, .nan]
        for length in invalidLengths {
            precondition(FloatingGeometry.insetRange(length: length, inset: 50) == 0...0)
        }
        print("Passed compact, zero-size and invalid floating geometry regressions")
    }
}
