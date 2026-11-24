#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

let rootDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let outURL = rootDir.appendingPathComponent("docs/social-preview.png")
let iconURL = rootDir.appendingPathComponent("docs/icon.png")

let W: CGFloat = 1280
let H: CGFloat = 640

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(W),
    pixelsHigh: Int(H),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
rep.size = NSSize(width: W, height: H)

NSGraphicsContext.saveGraphicsState()
let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = nsCtx
let ctx = nsCtx.cgContext
let colorSpace = CGColorSpaceCreateDeviceRGB()

// 1. Deep obsidian editorial gradient canvas
let bgGrad = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.086, green: 0.106, blue: 0.145, alpha: 1.0), // #161B25
        CGColor(red: 0.055, green: 0.067, blue: 0.094, alpha: 1.0)  // #0E1118
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0), options: [])

// Subtle ambient sapphire & violet glows
let blueGlow = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.345, green: 0.651, blue: 1.0, alpha: 0.14),
        CGColor(red: 0.345, green: 0.651, blue: 1.0, alpha: 0.0)
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(blueGlow, startCenter: CGPoint(x: 240, y: 470), startRadius: 0, endCenter: CGPoint(x: 240, y: 470), endRadius: 420, options: [.drawsAfterEndLocation])

let purpleGlow = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.824, green: 0.659, blue: 1.0, alpha: 0.10),
        CGColor(red: 0.824, green: 0.659, blue: 1.0, alpha: 0.0)
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(purpleGlow, startCenter: CGPoint(x: 980, y: 200), startRadius: 0, endCenter: CGPoint(x: 980, y: 200), endRadius: 380, options: [.drawsAfterEndLocation])

// Subtle architectural border frame
let outerFrame = CGPath(roundedRect: CGRect(x: 24, y: 24, width: W - 48, height: H - 48), cornerWidth: 20, cornerHeight: 20, transform: nil)
ctx.addPath(outerFrame)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.06))
ctx.setLineWidth(1.5)
ctx.strokePath()

// 2. Left Column: Icon + MarkRead Wordmark + Tagline + Pills
let leftX: CGFloat = 86

if let iconImg = NSImage(contentsOf: iconURL) {
    iconImg.draw(
        in: NSRect(x: leftX - 10, y: 396, width: 124, height: 124),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )
}

func drawText(_ string: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor, kern: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: kern
    ]
    NSAttributedString(string: string, attributes: attrs).draw(at: NSPoint(x: x, y: y))
}

drawText(
    "MarkRead",
    x: leftX,
    y: 306,
    font: NSFont.systemFont(ofSize: 64, weight: .bold),
    color: NSColor(calibratedRed: 0.95, green: 0.97, blue: 1.0, alpha: 1.0),
    kern: -1.6
)

drawText(
    "Minimal, free & offline Markdown reader",
    x: leftX,
    y: 256,
    font: NSFont.systemFont(ofSize: 23, weight: .regular),
    color: NSColor(calibratedRed: 0.67, green: 0.72, blue: 0.80, alpha: 1.0)
)

drawText(
    "Inspired by Typora's typography aesthetics",
    x: leftX,
    y: 222,
    font: NSFont.systemFont(ofSize: 20, weight: .regular),
    color: NSColor(calibratedRed: 0.49, green: 0.55, blue: 0.64, alpha: 1.0)
)

// Feature Pills
let pills: [(text: String, dot: CGColor)] = [
    ("macOS & Windows", CGColor(red: 0.345, green: 0.651, blue: 1.0, alpha: 1.0)),
    ("Highlight.js", CGColor(red: 1.0, green: 0.482, blue: 0.447, alpha: 1.0)),
    ("Quick Look", CGColor(red: 0.824, green: 0.659, blue: 1.0, alpha: 1.0))
]

var pillX = leftX
let pillY: CGFloat = 140
let pillH: CGFloat = 38
let pillFont = NSFont.systemFont(ofSize: 15, weight: .medium)

for pill in pills {
    let textW = NSAttributedString(string: pill.text, attributes: [.font: pillFont]).size().width
    let pillW = textW + 42
    let pillRect = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillH / 2, cornerHeight: pillH / 2, transform: nil)

    ctx.addPath(pillPath)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.055))
    ctx.fillPath()
    ctx.addPath(pillPath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.11))
    ctx.setLineWidth(1.0)
    ctx.strokePath()

    ctx.setFillColor(pill.dot)
    ctx.fillEllipse(in: CGRect(x: pillX + 14, y: pillY + 15, width: 8, height: 8))

    drawText(
        pill.text,
        x: pillX + 29,
        y: pillY + 10,
        font: pillFont,
        color: NSColor(calibratedRed: 0.86, green: 0.90, blue: 0.96, alpha: 1.0)
    )
    pillX += pillW + 12
}

// 3. Right Column: Sleek macOS Reader Window Preview Card
let winRect = CGRect(x: 660, y: 78, width: 548, height: 484)
let winPath = CGPath(roundedRect: winRect, cornerWidth: 16, cornerHeight: 16, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 48, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
ctx.addPath(winPath)
ctx.setFillColor(CGColor(red: 0.075, green: 0.090, blue: 0.114, alpha: 1.0)) // #13171D
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(winPath)
ctx.clip()

// Window titlebar
let titlebarH: CGFloat = 42
ctx.setFillColor(CGColor(red: 0.094, green: 0.114, blue: 0.145, alpha: 1.0))
ctx.fill(CGRect(x: winRect.minX, y: winRect.maxY - titlebarH, width: winRect.width, height: titlebarH))

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.07))
ctx.setLineWidth(1)
ctx.move(to: CGPoint(x: winRect.minX, y: winRect.maxY - titlebarH))
ctx.addLine(to: CGPoint(x: winRect.maxX, y: winRect.maxY - titlebarH))
ctx.strokePath()

// Traffic lights
let dotY = winRect.maxY - 26
let dotColors: [CGColor] = [
    CGColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 0.92),
    CGColor(red: 1.0, green: 0.74, blue: 0.18, alpha: 0.92),
    CGColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 0.92)
]
for (i, c) in dotColors.enumerated() {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: winRect.minX + 18 + CGFloat(i) * 20, y: dotY, width: 11, height: 11))
}

drawText(
    "README.md",
    x: winRect.midX - 42,
    y: winRect.maxY - 29,
    font: NSFont.systemFont(ofSize: 13.5, weight: .medium),
    color: NSColor(calibratedRed: 0.56, green: 0.62, blue: 0.70, alpha: 1.0)
)

// Document content inside window mockup
let docX = winRect.minX + 36
drawText(
    "Release Notes",
    x: docX,
    y: winRect.maxY - 102,
    font: NSFont.systemFont(ofSize: 30, weight: .bold),
    color: NSColor(calibratedRed: 0.93, green: 0.95, blue: 0.98, alpha: 1.0),
    kern: -0.6
)

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.setLineWidth(1)
ctx.move(to: CGPoint(x: docX, y: winRect.maxY - 114))
ctx.addLine(to: CGPoint(x: winRect.maxX - 36, y: winRect.maxY - 114))
ctx.strokePath()

drawText(
    "Everything renders locally. Free, no account.",
    x: docX,
    y: winRect.maxY - 150,
    font: NSFont.systemFont(ofSize: 16, weight: .regular),
    color: NSColor(calibratedRed: 0.70, green: 0.75, blue: 0.83, alpha: 1.0)
)

// Code block card inside mockup
let codeRect = CGRect(x: docX, y: winRect.maxY - 352, width: winRect.width - 72, height: 174)
let codePath = CGPath(roundedRect: codeRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
ctx.addPath(codePath)
ctx.setFillColor(CGColor(red: 0.090, green: 0.110, blue: 0.141, alpha: 1.0))
ctx.fillPath()
ctx.addPath(codePath)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.09))
ctx.setLineWidth(1)
ctx.strokePath()

// Code block header
ctx.setFillColor(CGColor(red: 0.115, green: 0.138, blue: 0.176, alpha: 1.0))
ctx.fill(CGRect(x: codeRect.minX + 1, y: codeRect.maxY - 30, width: codeRect.width - 2, height: 29))

let monoHeader = NSFont(name: "SF Mono", size: 11.5) ?? NSFont.monospacedSystemFont(ofSize: 11.5, weight: .medium)
drawText("swift", x: codeRect.minX + 14, y: codeRect.maxY - 22, font: monoHeader, color: NSColor(calibratedRed: 0.55, green: 0.61, blue: 0.70, alpha: 1.0))

// Syntax-highlighted code lines
let mono = NSFont(name: "SF Mono", size: 13.5) ?? NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular)
let kw = NSColor(calibratedRed: 1.0, green: 0.482, blue: 0.447, alpha: 1.0)     // #FF7B72
let ty = NSColor(calibratedRed: 0.824, green: 0.659, blue: 1.0, alpha: 1.0)    // #D2A8FF
let st = NSColor(calibratedRed: 0.647, green: 0.839, blue: 1.0, alpha: 1.0)    // #A5D6FF
let pl = NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.96, alpha: 1.0)     // #E6EDF3
let cm = NSColor(calibratedRed: 0.545, green: 0.580, blue: 0.620, alpha: 1.0)  // #8B949E

func drawCodeLine(_ tokens: [(String, NSColor)], y: CGFloat) {
    var x = codeRect.minX + 16
    for (text, color) in tokens {
        let attr = NSAttributedString(string: text, attributes: [.font: mono, .foregroundColor: color])
        attr.draw(at: NSPoint(x: x, y: y))
        x += attr.size().width
    }
}

drawCodeLine([("struct ", kw), ("MarkRead", ty), (": ", pl), ("Reader", ty), (" {", pl)], y: codeRect.maxY - 62)
drawCodeLine([("    let ", kw), ("themes ", pl), ("= [", pl), ("\"Night\"", st), (", ", pl), ("\"Newsprint\"", st), ("]", pl)], y: codeRect.maxY - 88)
drawCodeLine([("    let ", kw), ("offline ", pl), ("= ", pl), ("true", NSColor(calibratedRed: 0.475, green: 0.753, blue: 1.0, alpha: 1.0))], y: codeRect.maxY - 114)
drawCodeLine([("    // Zero network, zero account", cm)], y: codeRect.maxY - 140)
drawCodeLine([("}", pl)], y: codeRect.maxY - 162)

// Callout strip below code block
let calloutRect = CGRect(x: docX, y: winRect.minY + 38, width: winRect.width - 72, height: 64)
let calloutPath = CGPath(roundedRect: calloutRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
ctx.addPath(calloutPath)
ctx.setFillColor(CGColor(red: 0.247, green: 0.725, blue: 0.314, alpha: 0.09))
ctx.fillPath()
ctx.setFillColor(CGColor(red: 0.247, green: 0.725, blue: 0.314, alpha: 1.0))
ctx.fill(CGRect(x: calloutRect.minX, y: calloutRect.minY + 4, width: 3.5, height: calloutRect.height - 8))

drawText("Tip", x: calloutRect.minX + 16, y: calloutRect.maxY - 25, font: NSFont.systemFont(ofSize: 13.5, weight: .semibold), color: NSColor(calibratedRed: 0.247, green: 0.725, blue: 0.314, alpha: 1.0))
drawText("Press Spacebar in Finder for instant Quick Look preview.", x: calloutRect.minX + 16, y: calloutRect.minY + 14, font: NSFont.systemFont(ofSize: 13.5, weight: .regular), color: NSColor(calibratedRed: 0.76, green: 0.81, blue: 0.88, alpha: 1.0))

ctx.restoreGState()

// Crisp window border
ctx.addPath(winPath)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.14))
ctx.setLineWidth(1.2)
ctx.strokePath()

NSGraphicsContext.restoreGraphicsState()

if let data = rep.representation(using: .png, properties: [:]) {
    try data.write(to: outURL)
    print("Generated social preview: \(outURL.path)")
}
