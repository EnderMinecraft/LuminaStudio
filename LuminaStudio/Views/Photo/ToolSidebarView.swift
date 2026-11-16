import SwiftUI

public struct ToolSidebarView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ForEach(ActiveTool.allCases) { tool in
                Button {
                    viewModel.activeTool = tool
                    if tool == .crop {
                        viewModel.isCropActive = true
                    } else {
                        viewModel.isCropActive = false
                    }
                } label: {
                    Image(systemName: tool.icon)
                        .font(.system(size: 18))
                        .frame(width: 40, height: 40)
                        .foregroundStyle(viewModel.activeTool == tool ? Color.accentColor : Color.primary)
                        .background(
                            viewModel.activeTool == tool ?
                            Color.accentColor.opacity(0.18) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
