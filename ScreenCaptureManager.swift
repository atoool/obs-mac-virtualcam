import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreVideo

protocol ScreenCaptureManagerDelegate: AnyObject {
    func screenCaptureManager(_ manager: ScreenCaptureManager, didOutput pixelBuffer: CVPixelBuffer, at time: CMTime)
}

final class ScreenCaptureManager: NSObject {
    weak var delegate: ScreenCaptureManagerDelegate?

    private var stream: SCStream?
    private var streamOutput: SCStreamOutput?

    func startDisplayCapture(preferredFPS: Int = 60) async throws {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "No display available"])
        }

        let filter = SCContentFilter(display: display, excludingWindows: [], exceptingApps: [])
        let config = SCStreamConfiguration()
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(preferredFPS))
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.captureResolution = .best

        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        self.stream = stream

        let output = StreamOutputBridge(delegate: self)
        self.streamOutput = output
        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        try await stream.startCapture()
    }

    func stopCapture() async {
        try? await stream?.stopCapture()
        if let output = streamOutput {
            try? stream?.removeStreamOutput(output, type: .screen)
        }
        streamOutput = nil
        stream = nil
    }
}

extension ScreenCaptureManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("SCStream stopped: \(error)")
    }
}

private final class StreamOutputBridge: NSObject, SCStreamOutput {
    weak var delegate: ScreenCaptureManager?

    init(delegate: ScreenCaptureManager) {
        self.delegate = delegate
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen,
              let pb = sampleBuffer.imageBuffer else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if let delegate = delegate {
            delegate.delegate?.screenCaptureManager(delegate, didOutput: pb, at: time)
        }
    }
}
