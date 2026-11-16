import SwiftUI
import EditorCore

public struct LayerPanelView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @State private var editingLayerNameID: UUID?
    @State private var tempName: String = ""
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Layers", systemImage: "square.3.layers.3d.down.right")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.isLayerPanelPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Layer Opacity & Blend Mode Bar (for active layer)
            if let active = viewModel.activeLayer {
                VStack(spacing: 8) {
                    HStack {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { active.opacity },
                                set: { viewModel.setOpacity($0) }
                            ),
                            in: 0.0...1.0
                        )
                        Text("\(Int(active.opacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 40, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Blend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Blend Mode", selection: Binding(
                            get: { active.blendMode },
                            set: { viewModel.setBlendMode($0) }
                        )) {
                            ForEach(LuminaBlendMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Toggle("Clipping Mask", isOn: Binding(
                            get: { active.isClippingMask },
                            set: { active.isClippingMask = $0 }
                        ))
                        .font(.caption)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
                
                Divider()
            }
            
            // Layers List
            List {
                ForEach(viewModel.document.layers.reversed()) { layer in
                    LayerRowView(
                        layer: layer,
                        isActive: layer.id == viewModel.document.activeLayerID,
                        onSelect: {
                            viewModel.setActiveLayer(id: layer.id)
                        },
                        onToggleVisibility: {
                            viewModel.toggleVisibility(for: layer.id)
                        },
                        onToggleLock: {
                            viewModel.toggleLock(for: layer.id)
                        },
                        onRename: { newName in
                            viewModel.renameActiveLayer(to: newName)
                        }
                    )
                }
                .onMove { indices, newOffset in
                    // Invert index calculation because UI displays reversed (top layer first)
                    let total = viewModel.document.layers.count
                    for index in indices {
                        let actualSource = total - 1 - index
                        let actualDest = total - newOffset
                        viewModel.moveLayer(from: actualSource, to: actualDest)
                    }
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            // Bottom Action Bar
            HStack(spacing: 24) {
                Button {
                    viewModel.addBlankLayer()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                
                Button {
                    viewModel.duplicateActiveLayer()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                .disabled(viewModel.activeLayer == nil)
                
                Button(role: .destructive) {
                    viewModel.deleteActiveLayer()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(viewModel.document.layers.count <= 1)
            }
            .font(.subheadline)
            .padding()
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 320, maxWidth: 380)
        .background(.regularMaterial)
    }
}

public struct LayerRowView: View {
    public let layer: Layer
    public let isActive: Bool
    public let onSelect: () -> Void
    public let onToggleVisibility: () -> Void
    public let onToggleLock: () -> Void
    public let onRename: (String) -> Void
    
    @State private var isRenaming: Bool = false
    @State private var editedName: String = ""
    
    public var body: some View {
        HStack(spacing: 12) {
            // Visibility toggle
            Button {
                onToggleVisibility()
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                    .foregroundStyle(layer.isVisible ? .primary : .tertiary)
                    .font(.body)
            }
            .buttonStyle(.plain)
            
            // Thumbnail icon / preview placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: iconName(for: layer.kind))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            
            // Layer Name
            if isRenaming {
                TextField("Layer Name", text: $editedName, onCommit: {
                    onRename(editedName)
                    isRenaming = false
                })
                .textFieldStyle(.roundedBorder)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(layer.name)
                        .font(.subheadline.weight(isActive ? .semibold : .regular))
                    Text("\(layer.blendMode.rawValue) • \(Int(layer.opacity * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
                .onLongPressGesture {
                    editedName = layer.name
                    isRenaming = true
                }
            }
            
            Spacer()
            
            // Lock indicator
            Button {
                onToggleLock()
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .foregroundStyle(layer.isLocked ? .primary : .quaternary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .listRowBackground(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
    }
    
    private func iconName(for kind: LayerKind) -> String {
        switch kind {
        case .raster: return "photo"
        case .adjustment: return "slider.horizontal.3"
        case .text: return "textformat"
        case .shape: return "square.on.circle"
        case .vector: return "point.topleft.down.curvedto.point.bottomright.up"
        case .group: return "folder.fill"
        }
    }
}
