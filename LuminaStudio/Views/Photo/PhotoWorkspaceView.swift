import SwiftUI
import PhotosUI
import EditorCore

public struct PhotoWorkspaceView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                // Metal Canvas
                MetalCanvasRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
                
                // Rulers & Grid Overlay
                if viewModel.showRulersAndGrid {
                    RulerGridView(
                        canvasSize: viewModel.document.configuration.size,
                        viewport: viewModel.viewport,
                        showGrid: true,
                        showRulers: true
                    )
                }
                
                // Overlays
                if viewModel.activeSelectionMask.hasSelection {
                    SelectionOverlayView(
                        segments: viewModel.marchingAntsSegments,
                        canvasSize: viewModel.document.configuration.size,
                        viewport: viewModel.viewport
                    )
                }
                
                if viewModel.activeTool == .move {
                    TransformOverlayView(viewModel: viewModel)
                }
                
                if viewModel.isCropActive {
                    CropOverlayView(viewModel: viewModel)
                }
                
                // Live Histogram Floating HUD
                if viewModel.isHistogramPresented {
                    VStack {
                        HStack {
                            Spacer()
                            HistogramView(data: viewModel.histogramData)
                                .padding(.top, 60)
                                .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Top Bar & Tool Options
                VStack(spacing: 8) {
                    topToolbar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ToolOptionsBarView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    bottomStatusBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Left Tool Sidebar
                HStack {
                    ToolSidebarView(viewModel: viewModel)
                        .padding(.leading, 12)
                    Spacer()
                }
                
                // Side Drawer Panels (Layers & History)
                HStack {
                    Spacer()
                    if viewModel.isLayerPanelPresented {
                        LayerPanelView(viewModel: viewModel)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else if viewModel.isHistoryPanelPresented {
                        HistoryPanelView(viewModel: viewModel)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLayerPanelPresented)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isHistoryPanelPresented)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isHistogramPresented)
            .animation(.easeInOut(duration: 0.2), value: viewModel.activeTool)
            .sheet(isPresented: $viewModel.isNewCanvasSheetPresented) {
                NewCanvasSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isExportSheetPresented) {
                ExportSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isBrushSettingsPresented) {
                BrushSettingsSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isTextLayerSheetPresented) {
                NewTextLayerSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShapeLayerSheetPresented) {
                NewShapeLayerSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isAdjustmentsSheetPresented) {
                AdjustmentsSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isFiltersSheetPresented) {
                FiltersSheetView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.isCutoutRefineStudioPresented) {
                CutoutRefineStudioView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isPerformingAutoCutout {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Detecting subjects & segmenting...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .photosPicker(isPresented: $viewModel.isPhotoPickerPresented, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        #if canImport(UIKit)
                        if let img = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.importImage(img)
                            }
                        }
                        #endif
                    }
                }
            }
        }
    }
    
    private var topToolbar: some View {
        HStack(spacing: 12) {
            // New & Import Menu
            Menu {
                Button {
                    viewModel.isNewCanvasSheetPresented = true
                } label: {
                    Label("New Canvas", systemImage: "doc.badge.plus")
                }
                
                Button {
                    viewModel.isPhotoPickerPresented = true
                } label: {
                    Label("Import Photo", systemImage: "photo.badge.plus")
                }
                
                Divider()
                
                Button {
                    viewModel.startAutoCutout(personOnly: false)
                } label: {
                    Label("Auto Cutout (Remove Background)", systemImage: "person.crop.circle.badge.minus")
                }
                
                Button {
                    viewModel.isCutoutRefineStudioPresented = true
                } label: {
                    Label("Refine Cutout Studio...", systemImage: "sparkle.magnifyingglass")
                }
                
                Divider()
                
                Button {
                    viewModel.isAdjustmentsSheetPresented = true
                } label: {
                    Label("Adjustments...", systemImage: "slider.horizontal.3")
                }
                
                Button {
                    viewModel.isFiltersSheetPresented = true
                } label: {
                    Label("Filters...", systemImage: "camera.filters")
                }
            } label: {
                Image(systemName: "folder")
                    .font(.body.weight(.medium))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Undo & Redo
            HStack(spacing: 4) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .padding(8)
                }
                .disabled(!viewModel.commandManager.canUndo)
                
                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .padding(8)
                }
                .disabled(!viewModel.commandManager.canRedo)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Before / After Press-and-Hold Button
            Button {
                // Tapping toggles, press-and-hold handled via gesture
            } label: {
                Image(systemName: viewModel.isBeforeAfterBypassed ? "eye.slash.fill" : "eye.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.isBeforeAfterBypassed ? Color.orange : Color.primary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            ._onButtonGesture(pressing: { pressing in
                viewModel.isBeforeAfterBypassed = pressing
                if pressing {
                    viewModel.statusMessage = "Before (Press & Hold)"
                } else {
                    viewModel.statusMessage = "After (Adjusted)"
                }
            }, perform: {})
            
            // Live Histogram Toggle Button
            Button {
                viewModel.isHistogramPresented.toggle()
                if viewModel.isHistogramPresented {
                    viewModel.refreshHistogram()
                }
            } label: {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(viewModel.isHistogramPresented ? Color.accentColor : Color.primary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Zoom Controls
            HStack(spacing: 8) {
                Button {
                    viewModel.zoomToFit(containerSize: viewModel.viewport.viewportSize)
                } label: {
                    Text("Fit")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                
                Button {
                    viewModel.zoomTo100(containerSize: viewModel.viewport.viewportSize)
                } label: {
                    Text("100%")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                
                Text("\(Int(viewModel.viewport.zoom * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 44, alignment: .trailing)
                
                if abs(viewModel.viewport.rotationRadians) > 0.01 {
                    Button {
                        viewModel.resetRotation()
                    } label: {
                        Image(systemName: "compass.drawing")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Adjustments Direct Button
            Button {
                viewModel.isAdjustmentsSheetPresented = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // History Panel Toggle
            Button {
                viewModel.isHistoryPanelPresented.toggle()
                if viewModel.isHistoryPanelPresented {
                    viewModel.isLayerPanelPresented = false
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(viewModel.isHistoryPanelPresented ? Color.accentColor : Color.primary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Layer Panel Toggle
            Button {
                viewModel.isLayerPanelPresented.toggle()
                if viewModel.isLayerPanelPresented {
                    viewModel.isHistoryPanelPresented = false
                }
            } label: {
                Image(systemName: "square.3.layers.3d.down.right")
                    .foregroundStyle(viewModel.isLayerPanelPresented ? Color.accentColor : Color.primary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Export Button
            Button {
                viewModel.isExportSheetPresented = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
    
    private var bottomStatusBar: some View {
        HStack {
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(viewModel.document.configuration.width) × \(viewModel.document.configuration.height) px • \(viewModel.document.configuration.colorSpace.rawValue)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
