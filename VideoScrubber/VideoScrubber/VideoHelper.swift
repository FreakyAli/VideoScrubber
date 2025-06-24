import SwiftUI
import AVFoundation

class VideoHelper {
	
	static func getThumbnail(from asset: AVAsset?, at time: CMTime) -> CGImage? {
		do {
			guard let asset = asset else { return nil }
			let imgGenerator = AVAssetImageGenerator(asset: asset)
			imgGenerator.appliesPreferredTrackTransform = true
			let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
			return cgImage
		} catch _ {
			return nil
		}
	}
	
	static func generateFullTimelineThumbnails(
		_ player: AVPlayer,
		containerHeight: CGFloat,
		maxVisibleWidth: CGFloat,
		maxThumbnails: Int = 100
	) async -> [UIImage] {
		var images: [UIImage] = []
		
		guard let currentItem = player.currentItem else { return images }
		let asset = await currentItem.asset
		
		do {
			let duration = try await asset.load(.duration)
			let durationSeconds = CMTimeGetSeconds(duration)
			
			let estimatedCount = Int(durationSeconds / 2) // 1 frame every 2 seconds
			let frameCount = max(10, min(maxThumbnails, estimatedCount))
			
			for i in 0..<frameCount {
				let progress = Double(i) / Double(frameCount - 1)
				let seconds = progress * durationSeconds
				let time = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
				
				if let cgImage = getThumbnail(from: asset, at: time) {
					images.append(UIImage(cgImage: cgImage))
				}
			}
		} catch {
			print("Thumbnail generation error: \(error)")
		}
		
		return images
	}
	
	static func getDuration(_ player: AVPlayer) async -> CMTime? {
		guard let currentItem = player.currentItem else { return nil }
		let asset = await currentItem.asset
		
		do {
			let duration = try await asset.load(.duration)
			return duration
		} catch {
			print("Failed to load duration: \(error)")
			return nil
		}
	}
}
