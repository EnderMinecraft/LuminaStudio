import SwiftUI

@main
struct LuminaStudioApp: App {
    @State private var coordinator = RootCoordinator()
    
    var body: some Scene {
        WindowGroup {
            WorkspaceContainerView(coordinator: coordinator)
        }
    }
}
