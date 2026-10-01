# DeepfakeStudio live mode

The app now includes a native iOS real-time camera mode:

- Front-camera preview using `AVCaptureSession`
- Per-frame Vision face landmark detection
- Live face bounding boxes and orientation metadata
- Local recording using `AVCaptureMovieFileOutput`
- Consent/status watermark in the live preview
- `RealtimeFaceSwapService` integration point for an authenticated GPU backend
- `LiveStreamPublisher` integration point for WebRTC or another streaming transport

## Important platform limitation

Vision detects and tracks faces; it does not perform photorealistic identity replacement. A production face replacement requires a licensed, consent-based Core ML model or secure GPU backend. The supplied backend type is deliberately a non-operational integration point until an endpoint is configured.

An iOS app also cannot register an arbitrary system-wide OBS virtual camera using public iOS APIs. For OBS, use a companion macOS app/plugin or a WebRTC/NDI bridge that receives frames from the iOS app. Do not upload camera frames without explicit user consent and secure authentication.

## Required Info.plist keys

Add these keys to the app target:

```xml
<key>NSCameraUsageDescription</key>
<string>DeepfakeStudio uses the camera for live face tracking and recording.</string>
<key>NSMicrophoneUsageDescription</key>
<string>DeepfakeStudio uses the microphone when recording live video.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>DeepfakeStudio saves recordings to your photo library.</string>
```
