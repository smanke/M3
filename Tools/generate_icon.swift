#!/usr/bin/env swift
// Generates the app icon: a computer mouse leaving a dashed "mileage trail"
// on a gradient rounded-square background. Run with:
//   swift Tools/generate_icon.swift
// Produces Resources/AppIcon.png (1024x1024).

import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("no graphics context")
}

// MARK: - Background: rounded square, indigo -> cyan diagonal gradient

let cornerRadius: CGFloat = size * 0.225
let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()

let colors = [
    NSColor(calibratedRed: 0.30, green: 0.25, blue: 0.85, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.02, green: 0.66, blue: 0.85, alpha: 1.0).cgColor,
] as CFArray
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)
ctx.restoreGState()

// MARK: - Dashed mileage trail (a winding road behind the mouse)

ctx.saveGState()
let trail = CGMutablePath()
trail.move(to: CGPoint(x: size * 0.12, y: size * 0.20))
trail.addCurve(
    to: CGPoint(x: size * 0.88, y: size * 0.80),
    control1: CGPoint(x: size * 0.05, y: size * 0.55),
    control2: CGPoint(x: size * 0.55, y: size * 0.30)
)
ctx.addPath(trail)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.30).cgColor)
ctx.setLineWidth(size * 0.045)
ctx.setLineCap(.round)
ctx.setLineDash(phase: 0, lengths: [size * 0.035, size * 0.035])
ctx.strokePath()
ctx.restoreGState()

// Waypoint dots along the trail, fading in as they approach the mouse.
let waypoints: [(CGPoint, CGFloat)] = [
    (CGPoint(x: size * 0.16, y: size * 0.24), 0.22),
    (CGPoint(x: size * 0.28, y: size * 0.44), 0.35),
    (CGPoint(x: size * 0.46, y: size * 0.53), 0.5),
]
for (point, alpha) in waypoints {
    let r = size * 0.018
    let dotRect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
    ctx.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
    ctx.fillEllipse(in: dotRect)
}

// MARK: - Mouse silhouette (top-down), positioned upper-right along the trail

ctx.saveGState()
let mouseCenter = CGPoint(x: size * 0.63, y: size * 0.62)
let mouseWidth = size * 0.34
let mouseHeight = size * 0.46

// Drop shadow
ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.012), blur: size * 0.03, color: NSColor.black.withAlphaComponent(0.35).cgColor)

let mouseRect = CGRect(
    x: mouseCenter.x - mouseWidth / 2,
    y: mouseCenter.y - mouseHeight / 2,
    width: mouseWidth,
    height: mouseHeight
)
let mousePath = CGMutablePath()
mousePath.addPath(CGPath(
    roundedRect: mouseRect,
    cornerWidth: mouseWidth * 0.5,
    cornerHeight: mouseWidth * 0.5,
    transform: nil
))
ctx.addPath(mousePath)
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Button divider (top center line)
ctx.saveGState()
ctx.setStrokeColor(NSColor(calibratedWhite: 0.55, alpha: 1.0).cgColor)
ctx.setLineWidth(size * 0.006)
ctx.move(to: CGPoint(x: mouseCenter.x, y: mouseRect.maxY - mouseWidth * 0.08))
ctx.addLine(to: CGPoint(x: mouseCenter.x, y: mouseCenter.y + mouseHeight * 0.08))
ctx.strokePath()
ctx.restoreGState()

// Scroll wheel
ctx.saveGState()
let wheelWidth = mouseWidth * 0.10
let wheelHeight = mouseHeight * 0.14
let wheelRect = CGRect(
    x: mouseCenter.x - wheelWidth / 2,
    y: mouseRect.maxY - mouseWidth * 0.30,
    width: wheelWidth,
    height: wheelHeight
)
let wheelPath = CGPath(roundedRect: wheelRect, cornerWidth: wheelWidth / 2, cornerHeight: wheelWidth / 2, transform: nil)
ctx.addPath(wheelPath)
ctx.setFillColor(NSColor(calibratedRed: 0.30, green: 0.25, blue: 0.85, alpha: 1.0).cgColor)
ctx.fillPath()
ctx.restoreGState()

image.unlockFocus()

// MARK: - Write PNG

guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("failed to render PNG")
}

let outputPath = "Resources/AppIcon.png"
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
