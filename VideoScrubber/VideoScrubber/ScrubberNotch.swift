import SwiftUI
import AVFoundation

struct ScrubberNotch: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		
		let notchWidth: CGFloat = rect.width * 0.35
		
		// Start at top left corner
		path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
		
		// Top horizontal line to notch
		path.addLine(to: CGPoint(x: rect.minX + notchWidth, y: rect.minY))
		
		// Rounded inward notch
		path.addQuadCurve(
			to: CGPoint(x: rect.minX + notchWidth, y: rect.maxY),
			control: CGPoint(x: rect.minX, y: rect.midY)
		)
		
		// Bottom line to right
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		
		// Close path
		path.closeSubpath()
		
		return path
	}
}


