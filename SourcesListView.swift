import SwiftUI
import CoreMedia
import CoreVideo

struct SourcesListView: View {
    @ObservedObject var studio: StudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sources")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Add Screen Capture", action: studio.addScreenSource)
                    Button("Add Camera", action: studio.addCameraSource)
                    Divider()
                    Button("Start Screen Capture") {
                        Task {
                            let manager = ScreenCaptureManager()
                            _ = manager // keep strong reference in a static store
                            ScreenCaptureBridge.shared.manager = manager
                            manager.delegate = ScreenCaptureBridge.shared
                            try? await manager.startDisplayCapture()
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .menuStyle(.borderlessButton)
            }
            .padding([.top, .horizontal])

            List(selection: .constant(Set<UUID>())) {
                ForEach(studio.sources) { source in
                    HStack {
                        Text(source.name)
                        Spacer()
                        Button(role: .destructive) {
                            studio.removeSource(source)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }
}

#Preview {
    SourcesListView(studio: StudioViewModel())
        .frame(width: 240)
}

final class ScreenCaptureBridge: ScreenCaptureManagerDelegate {
    static let shared = ScreenCaptureBridge()
    var manager: ScreenCaptureManager?
    func screenCaptureManager(_ manager: ScreenCaptureManager, didOutput pixelBuffer: CVPixelBuffer, at time: CMTime) {
        CaptureHub.shared.update(pixelBuffer)
    }
}
