import SwiftUI
import VectorCore

public struct VectorToolbarView: View {
    @Bindable var viewModel: VectorEditorViewModel
    
    public init(viewModel: VectorEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Main Tool Icons Bar
            HStack(spacing: 12) {
                ForEach(VectorTool.allCases) { tool in
                    Button {
                        viewModel.activeTool = tool
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tool.rawValue)
                                .font(.system(size: 10))
                        }
                        .frame(width: 54, height: 48)
                        .background(viewModel.activeTool == tool ? Color.accentColor : Color.clear)
                        .foregroundColor(viewModel.activeTool == tool ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // Contextual Options Sub-Bar
            HStack(spacing: 16) {
                switch viewModel.activeTool {
                case .pen:
                    Button {
                        viewModel.finishPenPath(isClosed: true)
                    } label: {
                        Label("Close Path", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        viewModel.finishPenPath(isClosed: false)
                    } label: {
                        Text("Finish Open")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear") {
                        viewModel.penPoints.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    
                case .shape:
                    Picker("Shape Type", selection: $viewModel.activeShapeType) {
                        ForEach(VectorShapeType.allCases) { shape in
                            Label(shape.rawValue, systemImage: shape.systemImage).tag(shape)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                case .select:
                    if !viewModel.selectedNodeIDs.isEmpty {
                        Button(role: .destructive) {
                            viewModel.deleteSelectedNodes()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.caption)
                        }
                    } else {
                        Text("Tap an object to select and transform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                case .pencil:
                    Text("Freehand drawing — smooth curve auto-fitted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
    }
}
