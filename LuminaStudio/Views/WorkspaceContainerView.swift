import SwiftUI
import EditorCore
import VectorCore

public struct WorkspaceContainerView: View {
    @Bindable public var coordinator: RootCoordinator
    @State private var photoViewModel: PhotoEditorViewModel
    @State private var vectorViewModel: VectorEditorViewModel
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
        
        _photoViewModel = State(initialValue: pVM)
        _vectorViewModel = State(initialValue: vVM)
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
                    CollageWorkspacePlaceholderView(document: coordinator.collageDocument)
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
