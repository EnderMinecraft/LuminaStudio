import SwiftUI
import CollageCore

public struct CollageCellToolbarView: View {
    @Bindable var viewModel: CollageEditorViewModel
    
    public init(viewModel: CollageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        if viewModel.selectedCellID != nil {
            HStack(spacing: 16) {
                Button {
                    viewModel.rotateSelectedCell()
                } label: {
                    Label("Rotate 90°", systemImage: "rotate.right.fill")
                        .font(.caption.weight(.medium))
                }
                
                Button {
                    viewModel.flipSelectedCell(horizontal: true)
                } label: {
                    Label("Flip H", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
                        .font(.caption.weight(.medium))
                }
                
                Button {
                    viewModel.flipSelectedCell(horizontal: false)
                } label: {
                    Label("Flip V", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill")
                        .font(.caption.weight(.medium))
                }
                
                Divider()
                    .frame(height: 18)
                
                Button {
                    viewModel.selectedCellID = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 6)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
