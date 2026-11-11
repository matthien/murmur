import SwiftUI

/// A shape built from a simple SVG path (absolute M and C commands),
/// scaled from its view box into whatever frame it is given.
/// Stroke it after sizing so the line width stays constant.
struct SVGPathShape: Shape {
    let viewBox: CGSize
    let paths: [String]

    init(viewBox: CGSize, _ paths: String...) {
        self.viewBox = viewBox
        self.paths = paths
    }

    func path(in rect: CGRect) -> Path {
        var result = Path()
        for d in paths { result.addPath(Self.parse(d)) }
        let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: rect.width / viewBox.width, y: rect.height / viewBox.height)
        return result.applying(transform)
    }

    private static func parse(_ d: String) -> Path {
        var path = Path()
        var tokens = d.split(whereSeparator: { $0 == " " || $0 == "," })[...]
        var command: Character = "M"

        func number() -> CGFloat {
            CGFloat(Double(tokens.popFirst() ?? "0") ?? 0)
        }
        func point() -> CGPoint {
            let x = number()
            return CGPoint(x: x, y: number())
        }

        while let token = tokens.first {
            if let c = token.first, c.isLetter {
                command = c
                if token.count > 1 {
                    tokens[tokens.startIndex] = token.dropFirst()
                } else {
                    tokens.removeFirst()
                }
                continue
            }
            switch command {
            case "M":
                path.move(to: point())
                command = "L"
            case "L":
                path.addLine(to: point())
            case "C":
                let c1 = point(), c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            default:
                tokens.removeFirst()
            }
        }
        return path
    }
}

enum LineArt {
    static let recordRing = SVGPathShape(
        viewBox: CGSize(width: 220, height: 160),
        "M110 12 C150 10 179 40 178 80 C177 121 148 149 108 148 C68 147 41 119 42 79 C43 41 72 13 116 13"
    )

    static let soundLines = SVGPathShape(
        viewBox: CGSize(width: 220, height: 160),
        "M26 58 C18 70 18 90 26 102",
        "M12 48 C3 66 3 94 12 112",
        "M194 58 C202 70 202 90 194 102",
        "M208 48 C217 66 217 94 208 112"
    )

    static let todayCircle = SVGPathShape(
        viewBox: CGSize(width: 44, height: 40),
        "M22 4 C34 3 41 11 40 21 C39 31 30 37 20 36 C9 35 3 27 5 17 C7 9 14 4 26 5"
    )

    static let squiggleDivider = SVGPathShape(
        viewBox: CGSize(width: 334, height: 12),
        "M2 6 C60 2 110 9 170 5 C230 1 280 8 332 4"
    )

    static let chevronLeft = SVGPathShape(
        viewBox: CGSize(width: 24, height: 24),
        "M15 5 C12 7 10 10 8 12 C10 14 13 17 15 20"
    )

    static let chevronRight = SVGPathShape(
        viewBox: CGSize(width: 24, height: 24),
        "M9 5 C12 7 14 10 16 12 C14 14 11 17 9 20"
    )

    static let tabUnderline = SVGPathShape(
        viewBox: CGSize(width: 64, height: 10),
        "M2 6 C12 2 20 9 32 5 C44 1 52 8 62 4"
    )
}
