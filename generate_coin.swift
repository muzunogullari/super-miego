import Cocoa

// Create a dollar bill image
let size = CGSize(width: 64, height: 32)  // Bill proportions
let image = NSImage(size: size)

image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Green bill background
let billGreen = NSColor(red: 0.3, green: 0.6, blue: 0.35, alpha: 1.0)
let darkGreen = NSColor(red: 0.2, green: 0.45, blue: 0.25, alpha: 1.0)
let lightGreen = NSColor(red: 0.5, green: 0.75, blue: 0.5, alpha: 1.0)

// Main bill body
ctx.setFillColor(billGreen.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 32))

// Border
ctx.setStrokeColor(darkGreen.cgColor)
ctx.setLineWidth(2)
ctx.stroke(CGRect(x: 1, y: 1, width: 62, height: 30))

// Inner border pattern
ctx.setStrokeColor(lightGreen.cgColor)
ctx.setLineWidth(1)
ctx.stroke(CGRect(x: 4, y: 4, width: 56, height: 24))

// Draw $1
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 18),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraphStyle
]

let dollarText = "$1"
let textRect = CGRect(x: 0, y: 6, width: 64, height: 24)
dollarText.draw(in: textRect, withAttributes: attributes)

// Corner decorations
let cornerSize: CGFloat = 8
ctx.setFillColor(lightGreen.cgColor)
ctx.fill(CGRect(x: 2, y: 2, width: cornerSize, height: cornerSize))
ctx.fill(CGRect(x: 54, y: 2, width: cornerSize, height: cornerSize))
ctx.fill(CGRect(x: 2, y: 22, width: cornerSize, height: cornerSize))
ctx.fill(CGRect(x: 54, y: 22, width: cornerSize, height: cornerSize))

image.unlockFocus()

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "SuperMiego/Assets.xcassets/Sprites/coin.imageset/coin.png")
    try? pngData.write(to: url)
    print("Dollar bill image created!")
}
