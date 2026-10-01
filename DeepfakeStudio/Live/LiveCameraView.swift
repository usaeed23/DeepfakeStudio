import SwiftUI
import AVFoundation

struct LiveCameraView: View {
    @ObservedObject var camera: LiveCameraViewModel

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            ForEach(camera.faces) { face in
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.green, lineWidth: 2)
                        .frame(width: face.normalizedBounds.width * proxy.size.width,
                               height: face.normalizedBounds.height * proxy.size.height)
                        .position(x: face.normalizedBounds.midX * proxy.size.width,
                                  y: (1 - face.normalizedBounds.midY) * proxy.size.height)
                }
                .allowsHitTesting(false)
            }

            VStack {
                HStack {
                    Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.black.opacity(0.65), in: Capsule())
                    Spacer()
                    Text("Consent mode")
                        .font(.caption)
                        .padding(8)
                        .background(.black.opacity(0.65), in: Capsule())
                }
                .padding()
                Spacer()
                Text("Live preview tracks faces locally. Identity replacement requires your configured, consent-based processing service.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                HStack(spacing: 24) {
                    Button(camera.isRecording ? "Stop" : "Record") { camera.toggleRecording() }
                        .buttonStyle(.borderedProminent)
                        .tint(camera.isRecording ? .red : .purple)
                    Button("Stop camera") { camera.stop() }
                        .buttonStyle(.bordered)
                }
                .padding(.bottom)
            }
        }
        .task { camera.start() }
        .onDisappear { camera.stop() }
        .alert("Live Studio", isPresented: Binding(get: { camera.errorMessage != nil }, set: { _ in camera.errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(camera.errorMessage ?? "Unknown error")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) { }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
