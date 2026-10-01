import Foundation
import AVFoundation
import Vision
import CoreImage
import UIKit

struct FaceObservation: Identifiable {
    let id = UUID()
    let normalizedBounds: CGRect
    let yaw: Float?
    let pitch: Float?
}

@MainActor
final class LiveCameraViewModel: NSObject, ObservableObject {
    @Published private(set) var permissionDenied = false
    @Published private(set) var isRunning = false
    @Published private(set) var isRecording = false
    @Published private(set) var faces: [FaceObservation] = []
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "deepfake.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let visionQueue = DispatchQueue(label: "deepfake.camera.vision")
    private var configured = false

    func start() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                permissionDenied = true
                errorMessage = "Camera access is required for Live Studio. Enable it in Settings."
                return
            }
            configureIfNeeded()
            sessionQueue.async { [weak self] in
                guard let self, !self.session.isRunning else { return }
                self.session.startRunning()
                Task { @MainActor in self.isRunning = true }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            Task { @MainActor in self.isRunning = false }
        }
    }

    func toggleRecording() {
        guard isRunning else { return }
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            return
        }
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("live-\(UUID().uuidString).mov")
        sessionQueue.async { [weak self] in
            self?.movieOutput.startRecording(to: url, recordingDelegate: self!)
        }
        isRecording = true
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            errorMessage = "The front camera is unavailable on this device."
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
        session.commitConfiguration()
    }
}

extension LiveCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            let observations = (request.results as? [VNFaceObservation]) ?? []
            let mapped = observations.map {
                FaceObservation(normalizedBounds: $0.boundingBox, yaw: $0.yaw?.floatValue, pitch: $0.pitch?.floatValue)
            }
            Task { @MainActor in self?.faces = mapped }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
}

extension LiveCameraViewModel: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            self.isRecording = false
            if error == nil {
                self.errorMessage = "Recording saved temporarily. Use the export action to publish it."
            } else {
                self.errorMessage = "Recording failed. Please try again."
            }
        }
    }
}
