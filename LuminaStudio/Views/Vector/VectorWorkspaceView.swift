import SwiftUI
import VectorCore

public struct VectorWorkspaceView: View {
    @State public var viewModel: VectorEditorViewModel
    
    public init(viewModel: VectorEditorViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            // Main Canvas
            VectorCanvasView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Chrome Overlays
            VStack {
                // Top Toolbar
                VectorToolbarView(viewModel: viewModel)
                    .padding(.top, 8)
                
                Spacer()
                
                // Bottom Status Pill
                Text(viewModel.statusMessage)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.bottom, 12)
            }
            
            // Right Properties Inspector (Trailing edge)
            HStack {
                Spacer()
                VectorPropertiesPanelView(viewModel: viewModel)
                    .ignoresSafeArea(edges: .vertical)
            }
        }
        .sheet(isPresented: $viewModel.isExportSheetPresented) {
            VectorExportSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isTraceSheetPresented) {
            VectorTraceSheetView(viewModel: viewModel)
        }
    }
}
