import SwiftUI
import CollageCore

public struct CollageControlsPanelView: View {
    @Bindable var viewModel: CollageEditorViewModel
    
    public init(viewModel: CollageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Main Action Bar
            HStack(spacing: 16) {
                Button {
                    viewModel.isTemplateBrowserPresented = true
                } label: {
                    Label("Templates", systemImage: "square.grid.3x3.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                
                // Aspect Ratio Picker
                Picker("Aspect Ratio", selection: $viewModel.document.aspectRatioPreset) {
                    Text("1:1").tag(AspectRatioPreset.square)
                    Text("4:5").tag(AspectRatioPreset.portrait)
                    Text("9:16").tag(AspectRatioPreset.story)
                    Text("16:9").tag(AspectRatioPreset.landscape)
                    Text("A4").tag(AspectRatioPreset.a4)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                
                Spacer()
                
                // Export Button
                Button {
                    viewModel.isExportSheetPresented = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                
                // Open in Photo Editor
                Button {
                    viewModel.openInPhotoEditor()
                } label: {
                    Label("Open in Photo", systemImage: "photo.badge.arrow.forward.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Sliders for Spacing, Margins, Corner Radius
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Text("Spacing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $viewModel.document.cellSpacing, in: 0...32, step: 2)
                        .frame(width: 100)
                    Text("\(Int(viewModel.document.cellSpacing))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 20)
                }
                
                HStack(spacing: 8) {
                    Text("Margin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $viewModel.document.outerMargin, in: 0...48, step: 2)
                        .frame(width: 100)
                    Text("\(Int(viewModel.document.outerMargin))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 20)
                }
                
                HStack(spacing: 8) {
                    Text("Radius")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $viewModel.document.cornerRadius, in: 0...36, step: 2)
                        .frame(width: 100)
                    Text("\(Int(viewModel.document.cornerRadius))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 20)
                }
                
                HStack(spacing: 8) {
                    Text("Background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: viewModel.document.backgroundColorHex) ?? .white },
                        set: { viewModel.document.backgroundColorHex = $0.toHex() ?? "#FFFFFF" }
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private extension Color {
    init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean += "FF" }
        guard clean.count == 8, let val = UInt32(clean, radix: 16) else { return nil }
        let r = Double((val >> 24) & 0xFF) / 255.0
        let g = Double((val >> 16) & 0xFF) / 255.0
        let b = Double((val >> 8) & 0xFF) / 255.0
        let a = Double(val & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String? {
        #if canImport(UIKit)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let ir = Int(r * 255)
        let ig = Int(g * 255)
        let ib = Int(b * 255)
        return String(format: "#%02X%02X%02X", ir, ig, ib)
        #else
        return nil
        #endif
    }
}
