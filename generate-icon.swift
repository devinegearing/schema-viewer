#!/usr/bin/env swift
// Generates AppIcon.icns for SchemaViewer — ERD-style connected nodes icon
import AppKit

let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size
    let inset = s * 0.08
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = s * 0.22

    // Background — indigo gradient
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.39, green: 0.4, blue: 0.95, alpha: 1.0),
        NSColor(calibratedRed: 0.29, green: 0.27, blue: 0.85, alpha: 1.0),
    ])!
    gradient.draw(in: bgPath, angle: -45)

    // Subtle inner shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.04, color: CGColor(gray: 0, alpha: 0.3))
    ctx.restoreGState()

    // Draw three connected ERD boxes
    let boxW = s * 0.22
    let boxH = s * 0.14
    let headerH = s * 0.04
    let boxR = s * 0.02

    // Box positions (center of canvas)
    let cx = s / 2
    let cy = s / 2
    let topBox = CGRect(x: cx - boxW / 2, y: cy + s * 0.12, width: boxW, height: boxH)
    let leftBox = CGRect(x: cx - s * 0.22, y: cy - s * 0.18, width: boxW, height: boxH)
    let rightBox = CGRect(x: cx + s * 0.01, y: cy - s * 0.18, width: boxW, height: boxH)

    func drawBox(_ rect: CGRect, headerColor: NSColor) {
        // Card body
        let body = NSBezierPath(roundedRect: rect, xRadius: boxR, yRadius: boxR)
        NSColor.white.withAlphaComponent(0.95).setFill()
        body.fill()

        // Header bar
        let header = CGRect(x: rect.minX, y: rect.maxY - headerH, width: rect.width, height: headerH)
        let headerPath = NSBezierPath(roundedRect: header, xRadius: boxR, yRadius: boxR)
        headerColor.setFill()
        headerPath.fill()
        // Fill the bottom corners of the header
        let headerBottom = CGRect(x: rect.minX, y: rect.maxY - headerH, width: rect.width, height: headerH / 2)
        NSBezierPath(rect: headerBottom).fill()

        // Field lines
        let lineY1 = rect.maxY - headerH - rect.height * 0.35
        let lineY2 = rect.maxY - headerH - rect.height * 0.6
        let lineInset = rect.width * 0.12

        NSColor(white: 0.75, alpha: 1.0).setStroke()
        let line1 = NSBezierPath()
        line1.lineWidth = max(1, s * 0.005)
        line1.move(to: NSPoint(x: rect.minX + lineInset, y: lineY1))
        line1.line(to: NSPoint(x: rect.maxX - lineInset, y: lineY1))
        line1.stroke()

        let line2 = NSBezierPath()
        line2.lineWidth = max(1, s * 0.005)
        line2.move(to: NSPoint(x: rect.minX + lineInset, y: lineY2))
        line2.line(to: NSPoint(x: rect.maxX - lineInset * 2, y: lineY2))
        line2.stroke()
    }

    // Draw connection lines first (behind boxes)
    NSColor.white.withAlphaComponent(0.7).setStroke()
    let lineWidth = max(1.5, s * 0.012)

    // Top box → left box
    let path1 = NSBezierPath()
    path1.lineWidth = lineWidth
    path1.move(to: NSPoint(x: topBox.midX - topBox.width * 0.2, y: topBox.minY))
    path1.line(to: NSPoint(x: leftBox.midX, y: leftBox.maxY))
    path1.stroke()

    // Top box → right box
    let path2 = NSBezierPath()
    path2.lineWidth = lineWidth
    path2.move(to: NSPoint(x: topBox.midX + topBox.width * 0.2, y: topBox.minY))
    path2.line(to: NSPoint(x: rightBox.midX, y: rightBox.maxY))
    path2.stroke()

    // Left box → right box (dashed)
    let path3 = NSBezierPath()
    path3.lineWidth = lineWidth
    let pattern: [CGFloat] = [s * 0.015, s * 0.01]
    path3.setLineDash(pattern, count: 2, phase: 0)
    path3.move(to: NSPoint(x: leftBox.maxX, y: leftBox.midY))
    path3.line(to: NSPoint(x: rightBox.minX, y: rightBox.midY))
    path3.stroke()

    // Draw boxes on top
    drawBox(topBox, headerColor: NSColor(calibratedRed: 0.23, green: 0.51, blue: 0.96, alpha: 1.0))
    drawBox(leftBox, headerColor: NSColor(calibratedRed: 0.66, green: 0.33, blue: 0.97, alpha: 1.0))
    drawBox(rightBox, headerColor: NSColor(calibratedRed: 0.08, green: 0.72, blue: 0.65, alpha: 1.0))

    image.unlockFocus()
    return image
}

// Create iconset
let iconsetPath = "/tmp/SchemaViewer.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = renderIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { continue }
    try png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

// Convert to icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
try task.run()
task.waitUntilExit()
try? fm.removeItem(atPath: iconsetPath)

if task.terminationStatus == 0 {
    print("✓ AppIcon.icns generated")
} else {
    print("✗ iconutil failed with exit code \(task.terminationStatus)")
}
