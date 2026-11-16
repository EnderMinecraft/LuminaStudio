import SwiftUI
import CollageCore

public struct CollageTemplateBrowserView: View {
    @Bindable var viewModel: CollageEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhotoCount: Int = 3
    
    private let availableCounts = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    
    public init(viewModel: CollageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Photo Count Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableCounts, id: \.self) { count in
                            Button {
                                selectedPhotoCount = count
                            } label: {
                                Text("\(count) Photos")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedPhotoCount == count ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundColor(selectedPhotoCount == count ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // Templates Grid
                let filtered = TemplateRegistry.shared.templates(forPhotoCount: selectedPhotoCount)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(filtered) { template in
                            Button {
                                viewModel.applyTemplate(template)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    // Mini BSP Schematic Preview
                                    MiniCollagePreviewView(node: template.rootNodeBuilder())
                                        .frame(height: 120)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Text(template.name)
                                        .font(.caption.weight(.medium))
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.category)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.06), radius: 4)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Collage Templates (\(TemplateRegistry.shared.templates.count)+)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Mini Layout Preview

private struct MiniCollagePreviewView: View {
    let node: CollageLayoutNode
    
    var body: some View {
        GeometryReader { geometry in
            let (cells, _) = BSPLayoutSolver.shared.solve(
                node: node,
                in: CGRect(origin: .zero, size: geometry.size),
                spacing: 3.0,
                margin: 4.0
            )
            
            ZStack {
                ForEach(Array(cells.enumerated()), id: \.offset) { idx, item in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor.opacity(Double(0.3 + 0.1 * Double(idx % 6))))
                        .frame(width: item.rect.width, height: item.rect.height)
                        .position(x: item.rect.midX, y: item.rect.midY)
                }
            }
        }
    }
}
