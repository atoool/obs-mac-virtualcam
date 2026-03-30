import SwiftUI

struct PreviewContainerView: View {
    @ObservedObject var studio: StudioViewModel

    var body: some View {
        ZStack {
            RendererView()
                .background(Color.black)
                .overlay(alignment: .topLeading) {
                    Text("Preview")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding()
                }

            if studio.sources.isEmpty {
                ContentUnavailableView("No Sources", systemImage: "rectangle.on.rectangle.slash", description: Text("Add a screen or camera source to begin."))
            }
        }
        .padding()
    }
}

#Preview {
    PreviewContainerView(studio: StudioViewModel())
}
