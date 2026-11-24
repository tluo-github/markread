#!/usr/bin/env swift
import AppKit
import CoreGraphics
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

    // 1. Ambient macOS drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.34))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Clip to squircle and draw rich obsidian-slate editorial gradient
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let bgColors = [
        CGColor(red: 0.165, green: 0.196, blue: 0.255, alpha: 1.0), // Top: #2A3241
        CGColor(red: 0.102, green: 0.122, blue: 0.161, alpha: 1.0), // Mid: #1A1F29
        CGColor(red: 0.067, green: 0.082, blue: 0.110, alpha: 1.0)  // Bot: #11151C
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.52, 1.0])!
    ctx.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: canvasSize / 2, y: iconRect.maxY),
        end: CGPoint(x: canvasSize / 2, y: iconRect.minY),
        options: []
    )

    // Subtle upper ambient glow (startRadius: 0 so center blends smoothly)
    let glowColors = [
        CGColor(red: 0.345, green: 0.651, blue: 1.0, alpha: 0.15),
        CGColor(red: 0.345, green: 0.651, blue: 1.0, alpha: 0.0)
    ] as CFArray
    let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(
        glowGradient,
        startCenter: CGPoint(x: canvasSize * 0.5, y: iconRect.maxY - 90),
        startRadius: 0,
        endCenter: CGPoint(x: canvasSize * 0.5, y: iconRect.maxY - 90),
        endRadius: 540,
        options: [.drawsAfterEndLocation]
    )

    // Subtle editorial margin frame inside the dark card (like a refined dark book page)
    let pageRect = iconRect.insetBy(dx: 56, dy: 56)
    let pagePath = makeSquirclePath(in: pageRect, radius: 132)
    ctx.addPath(pagePath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.06))
    ctx.setLineWidth(2.5)
    ctx.strokePath()

    // 3. Centerpiece Serif "M" (paying tribute to Typora's editorial typography for MarkRead)
    let font = NSFont(name: "Georgia", size: 448)
        ?? NSFont(name: "Baskerville", size: 460)
        ?? NSFont.systemFont(ofSize: 440, weight: .semibold)

    let glyphStr = NSAttributedString(
        string: "M",
        attributes: [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        ]
    )
    let textSize = glyphStr.size()
    let textX = (canvasSize - textSize.width) / 2.0
    let textY = (canvasSize - textSize.height) / 2.0 + 66.0

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    glyphStr.draw(at: NSPoint(x: textX, y: textY))
    ctx.restoreGState()

    // 4. Syntax-highlight trio bar beneath the "T" (MarkRead's syntax-highlighting signature)
    let barY: CGFloat = iconRect.minY + 132
    let barHeight: CGFloat = 24
    let barRadius: CGFloat = barHeight / 2
    let gap: CGFloat = 22

    struct TokenBar {
        let width: CGFloat
        let color: CGColor
    }

    let bars: [TokenBar] = [
        TokenBar(width: 94, color: CGColor(red: 1.000, green: 0.482, blue: 0.447, alpha: 1.0)),  // Coral keyword (#FF7B72)
        TokenBar(width: 176, color: CGColor(red: 0.345, green: 0.651, blue: 1.000, alpha: 1.0)), // Sky blue (#58A6FF)
        TokenBar(width: 112, color: CGColor(red: 0.824, green: 0.659, blue: 1.000, alpha: 1.0))  // Soft lavender (#D2A8FF)
    ]

    let totalBarWidth = bars.reduce(0) { $0 + $1.width } + gap * CGFloat(bars.count - 1)
    var curX = (canvasSize - totalBarWidth) / 2.0

    for bar in bars {
        let rect = CGRect(x: curX, y: barY, width: bar.width, height: barHeight)
        let pill = CGPath(roundedRect: rect, cornerWidth: barRadius, cornerHeight: barRadius, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 18, color: bar.color.copy(alpha: 0.45))
        ctx.addPath(pill)
        ctx.setFillColor(bar.color)
        ctx.fillPath()
        ctx.restoreGState()
        curX += bar.width + gap
    }

    // 5. Crisp inner rim specular highlight along squircle border
    ctx.saveGState()
    let borderRect = iconRect.insetBy(dx: 2, dy: 2)
    let borderPath = makeSquirclePath(in: borderRect, radius: cornerRadius - 2)
    ctx.addPath(borderPath)
    ctx.setLineWidth(4.0)
    ctx.replacePathWithStrokedPath()
    ctx.clip()

    let rimColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.24),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.06),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.03)
    ] as CFArray
    let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 0.45, 1.0])!
    ctx.drawLinearGradient(
        rimGradient,
        start: CGPoint(x: canvasSize / 2, y: iconRect.maxY),
        end: CGPoint(x: canvasSize / 2, y: iconRect.minY),
        options: []
    )
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
