import SwiftUI

struct ControlsView: View {
    @ObservedObject var studio: StudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.headline)

            Toggle(isOn: $studio.isRecording) {
                Label("Record", systemImage: studio.isRecording ? "record.circle.fill" : "record.circle")
            }
            .toggleStyle(.switch)

            Toggle(isOn: $studio.isStreaming) {
                Label("Stream", systemImage: studio.isStreaming ? "dot.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
            }
            .toggleStyle(.switch)

            Spacer()
            Text("Status:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(statusText)
                .font(.callout)
        }
        .padding()
    }

    private var statusText: String {
        switch (studio.isRecording, studio.isStreaming) {
        case (true, true): return "Recording and Streaming"
        case (true, false): return "Recording"
        case (false, true): return "Streaming"
        default: return "Idle"
        }
    }
}

#Preview {
    ControlsView(studio: StudioViewModel())
        .frame(width: 280)
}
