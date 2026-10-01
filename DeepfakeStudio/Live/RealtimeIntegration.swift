import Foundation
import CoreMedia
import UIKit

/// Production integration point for a real-time identity-replacement backend.
/// The app intentionally does not ship a face-recognition model or silently upload
/// camera frames. Implement this protocol only with documented consent and a secure,
/// authenticated service.
protocol RealtimeFaceSwapService {
    func transform(frame: CMSampleBuffer, sourceFace: UIImage) async throws -> CMSampleBuffer
}

/// A real implementation should use WebRTC, a signed WebSocket protocol, or an
/// authenticated GPU endpoint. It must preserve frame timing and return a frame
/// suitable for preview/recording.
struct BackendRealtimeFaceSwapService: RealtimeFaceSwapService {
    let endpoint: URL
    let bearerToken: String

    func transform(frame: CMSampleBuffer, sourceFace: UIImage) async throws -> CMSampleBuffer {
        throw NSError(domain: "DeepfakeStudio", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Configure a consent-based GPU transform endpoint before enabling identity replacement."
        ])
    }
}

/// iOS does not expose a public API for registering an arbitrary system virtual
/// camera. OBS output should be implemented by a companion macOS app/plugin or
/// an approved WebRTC/NDI bridge that consumes this stream.
protocol LiveStreamPublisher {
    func start() async throws
    func publish(_ sampleBuffer: CMSampleBuffer) async throws
    func stop()
}
