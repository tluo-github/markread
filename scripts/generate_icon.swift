#!/usr/bin/env swift
import AppKit
import CoreGraphics
import CoreText
import Foundation

let rootDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let iconsetDir = rootDir.appendingPathComponent("MarkRead/Assets.xcassets/AppIcon.appiconset")

let canvasSize: CGFloat = 1024

func makeSquirclePath(in rect: CGRect, radius: CGFloat) -> CGPath {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let cgPath = CGMutablePath()
    var points = [NSPoint](repeating: .zero, count: 3)
    for i in 0..<path.elementCount {
        let type = path.element(at: i, associatedPoints: &points)
        switch type {
        case .moveTo:
            cgPath.move(to: points[0])
        case .lineTo:
            cgPath.addLine(to: points[0])
        case .curveTo, .cubicCurveTo:
            cgPath.addCurve(to: points[2], control1: points[0], control2: points[1])
        case .quadraticCurveTo:
            cgPath.addQuadCurve(to: points[1], control: points[0])
        case .closePath:
            cgPath.closeSubpath()
        @unknown default:
            break
        }
    }
    return cgPath
}

func renderMasterIcon() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize),
        pixelsHigh: Int(canvasSize),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: canvasSize, height: canvasSize)

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    ctx.clear(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))

    // macOS HIG squircle bounds: 824x824 centered in 1024x1024
    let inset: CGFloat = 100
    let iconRect = CGRect(x: inset, y: inset, width: canvasSize - inset * 2, height: canvasSize - inset * 2)
    let cornerRadius: CGFloat = 186
    let squirclePath = makeSquirclePath(in: iconRect, radius: cornerRadius)

    // 1. Soft macOS drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Clip to squircle and fill with a clean white (very faint top-to-bottom falloff)
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let bgColors = [
        CGColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.0), // Top: #FFFFFF
        CGColor(red: 0.957, green: 0.961, blue: 0.969, alpha: 1.0)  // Bot: #F4F5F7
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: canvasSize / 2, y: iconRect.maxY),
        end: CGPoint(x: canvasSize / 2, y: iconRect.minY),
        options: []
    )

    // 3. Centerpiece serif "M"
    let font = NSFont(name: "Georgia", size: 500)
        ?? NSFont(name: "Baskerville", size: 512)
        ?? NSFont.systemFont(ofSize: 480, weight: .semibold)

    let glyphStr = NSAttributedString(
        string: "M",
        attributes: [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.098, green: 0.110, blue: 0.133, alpha: 1.0) // #191C22
        ]
    )
    // Center on the glyph's actual ink bounds, not the line box
    let line = CTLineCreateWithAttributedString(glyphStr)
    let ink = CTLineGetImageBounds(line, ctx)
    let textX = (canvasSize - ink.width) / 2.0 - ink.minX
    let textY = (canvasSize - ink.height) / 2.0 - ink.minY
    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)

    // 4. Hairline rim so the white tile still reads on white backgrounds
    ctx.saveGState()
    let borderRect = iconRect.insetBy(dx: 1, dy: 1)
    let borderPath = makeSquirclePath(in: borderRect, radius: cornerRadius - 1)
    ctx.addPath(borderPath)
    ctx.setLineWidth(2.0)
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.08))
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // End squircle clip
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try data.write(to: url)
}

func resize(_ source: NSImage, pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    source.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: NSRect(origin: .zero, size: source.size),
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let masterRep = renderMasterIcon()
let masterImage = NSImage(size: NSSize(width: canvasSize, height: canvasSize))
masterImage.addRepresentation(masterRep)

let specs: [(filename: String, size: String, scale: String, pixels: Int)] = [
    ("icon_16x16.png", "16x16", "1x", 16),
    ("icon_16x16@2x.png", "16x16", "2x", 32),
    ("icon_32x32.png", "32x32", "1x", 32),
    ("icon_32x32@2x.png", "32x32", "2x", 64),
    ("icon_128x128.png", "128x128", "1x", 128),
    ("icon_128x128@2x.png", "128x128", "2x", 256),
    ("icon_256x256.png", "256x256", "1x", 256),
    ("icon_256x256@2x.png", "256x256", "2x", 512),
    ("icon_512x512.png", "512x512", "1x", 512),
    ("icon_512x512@2x.png", "512x512", "2x", 1024)
]

try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

var imagesJSON: [[String: String]] = []
for spec in specs {
    let rep = spec.pixels == 1024 ? masterRep : resize(masterImage, pixels: spec.pixels)
    try savePNG(rep, to: iconsetDir.appendingPathComponent(spec.filename))
    imagesJSON.append([
        "filename": spec.filename,
        "idiom": "mac",
        "scale": spec.scale,
        "size": spec.size
    ])
}

let contents: [String: Any] = [
    "images": imagesJSON,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]
let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: iconsetDir.appendingPathComponent("Contents.json"))

print("Generated 10 macOS AppIcon assets in \(iconsetDir.path)")

// Generate Windows Tauri icons (PNGs + multi-resolution ICO)
let winIconsDir = rootDir.appendingPathComponent("windows/src-tauri/icons")
try FileManager.default.createDirectory(at: winIconsDir, withIntermediateDirectories: true)

let winPngSpecs: [(filename: String, pixels: Int)] = [
    ("32x32.png", 32),
    ("128x128.png", 128),
    ("128x128@2x.png", 256),
    ("icon.png", 512)
]
for spec in winPngSpecs {
    let rep = resize(masterImage, pixels: spec.pixels)
    try savePNG(rep, to: winIconsDir.appendingPathComponent(spec.filename))
}

// Build standard multi-resolution Windows ICO (PNG-encoded entries: 16, 24, 32, 48, 64, 128, 256)
let icoSizes = [16, 24, 32, 48, 64, 128, 256]
var pngFrames: [(size: Int, data: Data)] = []
for px in icoSizes {
    let rep = resize(masterImage, pixels: px)
    if let data = rep.representation(using: .png, properties: [:]) {
        pngFrames.append((px, data))
    }
}

var icoData = Data()
func appendUInt16LE(_ v: UInt16) {
    var le = v.littleEndian
    icoData.append(Data(bytes: &le, count: 2))
}
func appendUInt32LE(_ v: UInt32) {
    var le = v.littleEndian
    icoData.append(Data(bytes: &le, count: 4))
}

// ICONDIR header (6 bytes)
appendUInt16LE(0) // reserved
appendUInt16LE(1) // type = 1 (ICO)
appendUInt16LE(UInt16(pngFrames.count))

var offset = UInt32(6 + 16 * pngFrames.count)
for frame in pngFrames {
    let dimByte: UInt8 = frame.size >= 256 ? 0 : UInt8(frame.size)
    icoData.append(dimByte)          // width
    icoData.append(dimByte)          // height
    icoData.append(0)                // color palette count
    icoData.append(0)                // reserved
    appendUInt16LE(1)                // color planes
    appendUInt16LE(32)               // bits per pixel
    appendUInt32LE(UInt32(frame.data.count))
    appendUInt32LE(offset)
    offset += UInt32(frame.data.count)
}
for frame in pngFrames {
    icoData.append(frame.data)
}

try icoData.write(to: winIconsDir.appendingPathComponent("icon.ico"))
print("Generated Windows PNG & multi-res ICO assets in \(winIconsDir.path)")
