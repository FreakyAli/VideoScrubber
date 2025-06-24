import SwiftUI
import AVFoundation

struct VideoScrubber: View {
	let player: AVPlayer
	private let seekThrottleInterval: TimeInterval = 0.1
	var onAttemptScrubWhileCameraRollSelected: (() -> Void)?
	var isCameraRollThumbnailSelected: Bool
	
	@Binding var isPlaying: Bool
	@Binding var isTracking: Bool
	@Binding var selectedThumbnailTime: Double
	
	@State private var isLoading: Bool = true
	@State private var thumbnails: [UIImage] = []
	@State private var duration: CMTime = .zero
	@State private var thumbWidth: CGFloat = 60
	@State private var lastSeekTime: Date = .distantPast
	@State private var thumbnailOffset: CGFloat = 0
	
	private let notchWidth: CGFloat = 30
	
	var body: some View {
		GeometryReader { geo in
			let viewWidth = geo.size.width
			let viewHeight = geo.size.height
			
			ZStack {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 0) {
						// Padding before frames
						Color.clear.frame(width: viewWidth / 2)
						
						// Left notch (scrolls with content)
						ScrubberNotch()
							.fill(Color.steelBlueGray)
							.frame(width: notchWidth, height: viewHeight + 4)
						
						// Thumbnail area
						thumbnailStrip(viewHeight: viewHeight)
						
						
						// Right notch (scrolls with content)
						ScrubberNotch()
							.fill(Color.steelBlueGray)
							.frame(width: notchWidth, height: viewHeight + 4)
							.rotationEffect(.degrees(180))
						
						// Padding after frames
						Color.clear.frame(width: viewWidth / 2)
					}
				}
				
				// Center playhead indicator
				Rectangle()
					.fill(Color.white)
					.frame(width: 1.5, height: viewHeight + 10)
					.cornerRadius(1.5)
			}
			.onAppear {
				Task { @MainActor in
					withAnimation(.easeOut(duration: 0.25)) {
						isLoading = true
					}
					
					if let d = await VideoHelper.getDuration(player) {
						duration = d
					}
					
					thumbnails = await VideoHelper.generateFullTimelineThumbnails(
						player, containerHeight: viewHeight, maxVisibleWidth: UIScreen.main.bounds.width
					)
					
					if let first = thumbnails.first {
						let ratio = first.size.width / first.size.height
						thumbWidth = viewHeight * ratio
					}
					
					withAnimation(.easeIn(duration: 0.25)) {
						isLoading = false
					}
				}
			}
		}
	}
	
	@ViewBuilder
	private func thumbnailStrip(viewHeight: CGFloat) -> some View {
		if isLoading && thumbnails.isEmpty {
			HStack(spacing: 0) {
				ForEach(0..<5, id: \.self) { index in
					RoundedRectangle(cornerRadius: 6)
						.fill(Color.white.opacity(0.15))
						.frame(width: 90, height: viewHeight)
						.opacity(Double.random(in: 0.6...0.9))
						.padding(.horizontal, 1)
						.redacted(reason: .placeholder)
					
				}
			}
		} else {
			LazyHStack(spacing: 0) {
				ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, img in
					Image(uiImage: img)
						.resizable()
						.scaledToFill()
						.frame(width: thumbWidth, height: viewHeight)
						.clipped()
						.transition(.opacity)
						.overlay(
							VStack {
								Rectangle().fill(Color.steelBlueGray).frame(height: 3)
								Spacer()
								Rectangle().fill(Color.steelBlueGray).frame(height: 3)
							}
								.padding(.vertical, -2)
						)
				}
			}
			.background(
				GeometryReader { geo in
					Color.clear
						.onChange(of: geo.frame(in: .global).minX) { newMinX in
							if isCameraRollThumbnailSelected {
								onAttemptScrubWhileCameraRollSelected?()
								return
							}
							let screenCenter = UIScreen.main.bounds.width / 2
							let scrollX = -newMinX + screenCenter
							thumbnailOffset = scrollX
							
							let now = Date()
							if now.timeIntervalSince(lastSeekTime) > seekThrottleInterval,
							   duration.seconds > 0 {
								lastSeekTime = now
								
								let visibleThumbnailsWidth = CGFloat(thumbnails.count) * thumbWidth
								let progress = min(max(scrollX / visibleThumbnailsWidth, 0), 1)
								let newTime = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
								player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
								selectedThumbnailTime = newTime.seconds
							}
						}
				}
			)
		}
	}
}


