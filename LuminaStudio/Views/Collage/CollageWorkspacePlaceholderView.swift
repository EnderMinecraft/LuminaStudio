import SwiftUI
import CollageCore

public struct CollageWorkspacePlaceholderView: View {
    public let document: CollageDocument
    
    public init(document: CollageDocument) {
        self.document = document
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "rectangle.split.2x2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                
                Text(document.title)
                    .font(.title2.weight(.bold))
                
                Text("Collage Mini Mode initialized with 40+ built-in BSP templates.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Aspect Ratio: \(document.aspectRatioPreset.rawValue) • Spacing: \(Int(document.cellSpacing))pt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
    }
}
