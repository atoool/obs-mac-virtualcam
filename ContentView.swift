import SwiftUI

struct ContentView: View {
    @StateObject private var studio = StudioViewModel()

    var body: some View {
        NavigationSplitView {
            SourcesListView(studio: studio)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } content: {
            PreviewContainerView(studio: studio)
                .navigationSplitViewColumnWidth(min: 400, ideal: 800)
        } detail: {
            ControlsView(studio: studio)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        }
    }
}

#Preview {
    ContentView()
}
