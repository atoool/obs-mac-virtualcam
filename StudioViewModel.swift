import Foundation
import Combine

enum SourceType: String, Identifiable, CaseIterable {
    case screen
    case camera

    var id: String { rawValue }
}

struct Source: Identifiable, Hashable {
    let id: UUID = UUID()
    var type: SourceType
    var name: String
}

final class StudioViewModel: ObservableObject {
    @Published var sources: [Source] = []
    @Published var isRecording: Bool = false
    @Published var isStreaming: Bool = false

    func addScreenSource() {
        sources.append(Source(type: .screen, name: "Screen Capture"))
    }

    func addCameraSource() {
        sources.append(Source(type: .camera, name: "Camera"))
    }

    func removeSource(_ source: Source) {
        sources.removeAll { $0.id == source.id }
    }
}
