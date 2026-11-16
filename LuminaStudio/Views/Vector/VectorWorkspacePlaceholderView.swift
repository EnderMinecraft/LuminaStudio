import SwiftUI
import VectorCore

public struct VectorWorkspacePlaceholderView: View {
    public let document: VectorDocument
    
    public init(document: VectorDocument) {
        self.document = document
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                
                Text(document.title)
                    .font(.title2.weight(.bold))
                
                Text("Vector workspace is initialized and ready.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let artboard = document.activeArtboard {
                    Text("Active Artboard: \(artboard.name) (\(Int(artboard.size.width)) × \(Int(artboard.size.height)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
    }
}
