import SwiftUI
import CollageCore

public struct CollageWorkspaceView: View {
    @State public var viewModel: CollageEditorViewModel
    
    public init(viewModel: CollageEditorViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            // Main Interactive Canvas
            CollageCanvasView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Overlays
            VStack {
                // Top Status Header
                HStack {
                    Text(viewModel.document.title)
                        .font(.headline)
                    Spacer()
                    Text(viewModel.statusMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Floating Cell Toolbar (appears when a cell is tapped)
                CollageCellToolbarView(viewModel: viewModel)
                    .padding(.top, 8)
                
                Spacer()
                
                // Bottom Controls Panel
                CollageControlsPanelView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isTemplateBrowserPresented) {
            CollageTemplateBrowserView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isExportSheetPresented) {
            CollageExportSheetView(viewModel: viewModel)
        }
    }
}
