import SwiftUI
import EditorCore
import VectorCore
import CollageCore

public struct WorkspaceContainerView: View {
    @Bindable public var coordinator: RootCoordinator
    @State private var photoViewModel: PhotoEditorViewModel
    @State private var vectorViewModel: VectorEditorViewModel
    @State private var collageViewModel: CollageEditorViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
        let pVM = PhotoEditorViewModel(
            document: coordinator.photoDocument,
            commandManager: coordinator.photoCommandManager
        )
        let vVM = VectorEditorViewModel(
            document: coordinator.vectorDocument,
            commandManager: coordinator.vectorCommandManager
        )
        let cVM = CollageEditorViewModel(
            document: coordinator.collageDocument,
            commandManager: coordinator.collageCommandManager
        )
        
        vVM.onSendToPhoto = { pixelBuffer, size in
            let newLayer = Layer(
                name: "Vector Artwork",
                kind: .vector(documentID: coordinator.vectorDocument.id),
                rawPixelData: Data(pixelBuffer),
                pixelWidth: Int(size.width),
                pixelHeight: Int(size.height)
            )
            pVM.document.layers.append(newLayer)
            pVM.document.selectedLayerID = newLayer.id
            coordinator.switchWorkspace(to: .photo)
        }
        
        cVM.onOpenInPhotoEditor = { cells, canvasSize, cornerRadius, bgColorHex in
            pVM.document.configuration.size = canvasSize
            pVM.document.layers.removeAll()
            
            let bgLayer = Layer(
                name: "Collage Background",
                kind: .raster(assetID: nil),
                pixelWidth: Int(canvasSize.width),
                pixelHeight: Int(canvasSize.height)
            )
            pVM.document.layers.append(bgLayer)
            
            for (idx, item) in cells.enumerated() {
                let cellW = max(1, Int(item.rect.width))
                let cellH = max(1, Int(item.rect.height))
                var maskBytes = [UInt8](repeating: 255, count: cellW * cellH)
                let r = Int(cornerRadius)
                if r > 0 {
                    for y in 0..<cellH {
                        for x in 0..<cellW {
                            let inCornerTL = x < r && y < r && (r - x)*(r - x) + (r - y)*(r - y) > r*r
                            let inCornerTR = x >= cellW - r && y < r && (x - (cellW - r - 1))*(x - (cellW - r - 1)) + (r - y)*(r - y) > r*r
                            let inCornerBL = x < r && y >= cellH - r && (r - x)*(r - x) + (y - (cellH - r - 1))*(y - (cellH - r - 1)) > r*r
                            let inCornerBR = x >= cellW - r && y >= cellH - r && (x - (cellW - r - 1))*(x - (cellW - r - 1)) + (y - (cellH - r - 1))*(y - (cellH - r - 1)) > r*r
                            if inCornerTL || inCornerTR || inCornerBL || inCornerBR {
                                maskBytes[y * cellW + x] = 0
                            }
                        }
                    }
                }
                
                let mask = LayerMask(data: Data(maskBytes), width: cellW, height: cellH)
                let cellLayer = Layer(
                    name: "Cell \(idx + 1)",
                    transform: Transform2D(translation: item.rect.origin),
                    mask: mask,
                    kind: .raster(assetID: item.cell.assetID),
                    pixelWidth: cellW,
                    pixelHeight: cellH
                )
                pVM.document.layers.append(cellLayer)
            }
            
            if let last = pVM.document.layers.last {
                pVM.document.selectedLayerID = last.id
            }
            coordinator.switchWorkspace(to: .photo)
        }
        
        _photoViewModel = State(initialValue: pVM)
        _vectorViewModel = State(initialValue: vVM)
        _collageViewModel = State(initialValue: cVM)
    }
    
    public var body: some View {
        ZStack {
            // Workspace Contents (all live in memory to prevent state loss)
            Group {
                switch coordinator.activeWorkspace {
                case .photo:
                    PhotoWorkspaceView(viewModel: photoViewModel)
                case .vector:
                    VectorWorkspaceView(viewModel: vectorViewModel)
                case .collage:
                    CollageWorkspaceView(viewModel: collageViewModel)
                }
            }
            
            // Top Navigation Bar on iPad / Regular Size Class
            if horizontalSizeClass == .regular {
                VStack {
                    HStack {
                        Spacer()
                        Picker("Workspace", selection: $coordinator.activeWorkspace) {
                            ForEach(WorkspaceMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 360)
                        .padding(.top, 12)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        // iPhone Bottom Tab Bar in Compact Size Class
        .safeAreaInset(edge: .bottom) {
            if horizontalSizeClass == .compact {
                HStack {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Button {
                            coordinator.switchWorkspace(to: mode)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: mode.systemImage)
                                    .font(.system(size: 20))
                                Text(mode.rawValue)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(coordinator.activeWorkspace == mode ? Color.accentColor : Color.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        // Keyboard Shortcuts for iPad & Mac Catalyst
        .keyboardShortcut("z", modifiers: .command)
        .onKeyPress(KeyEquivalent("z"), phases: .down) { press in
            if press.modifiers.contains(.shift) {
                photoViewModel.redo()
            } else {
                photoViewModel.undo()
            }
            return .handled
        }
    }
}
