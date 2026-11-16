import SwiftUI
import EditorCore

public struct HistoryPanelView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.isHistoryPanelPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // History list
            let entries = viewModel.commandManager.historyEntries()
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No actions in history yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(entries) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: entry.isCurrent ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(entry.isCurrent ? Color.accentColor : Color.secondary)
                                .font(.body)
                            
                            Text(entry.name)
                                .font(.subheadline.weight(entry.isCurrent ? .semibold : .regular))
                            
                            Spacer()
                            
                            Text(entry.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(entry.isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
                    }
                }
                .listStyle(.plain)
            }
            
            Divider()
            
            // Undo/Redo quick buttons
            HStack(spacing: 24) {
                Button {
                    viewModel.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.commandManager.canUndo)
                
                Button {
                    viewModel.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!viewModel.commandManager.canRedo)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 300, maxWidth: 360)
        .background(.regularMaterial)
    }
}
