import SwiftUI
import VectorCore

public struct VectorPropertiesPanelView: View {
    @Bindable var viewModel: VectorEditorViewModel
    
    public init(viewModel: VectorEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Workspace Actions Header
                HStack {
                    Text("Vector Inspector")
                        .font(.headline)
                    Spacer()
                    Button {
                        viewModel.isTraceSheetPresented = true
                    } label: {
                        Label("Trace Image", systemImage: "waveform.path.ecg")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Colors & Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Fill Color")
                            .font(.caption)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: viewModel.fillColorHex) ?? .blue },
                            set: { viewModel.fillColorHex = $0.toHex() ?? "#3B82F6" }
                        ))
                    }
                    
                    HStack {
                        Text("Stroke Color")
                            .font(.caption)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: viewModel.strokeColorHex) ?? .blue },
                            set: { viewModel.strokeColorHex = $0.toHex() ?? "#1E40AF" }
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Stroke Width")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(viewModel.strokeWidth)) px")
                                .font(.caption.monospacedDigit())
                        }
                        Slider(value: $viewModel.strokeWidth, in: 0...24, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Opacity")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(viewModel.opacity * 100))%")
                                .font(.caption.monospacedDigit())
                        }
                        Slider(value: Binding(
                            get: { Double(viewModel.opacity) },
                            set: { viewModel.opacity = Float($0) }
                        ), in: 0...1)
                    }
                }
                
                Divider()
                
                // Alignment & Distribution
                VStack(alignment: .leading, spacing: 10) {
                    Text("Alignment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Button { viewModel.alignSelected(alignment: .left) } label: {
                            Image(systemName: "align.horizontal.left.fill")
                        }
                        Button { viewModel.alignSelected(alignment: .centerX) } label: {
                            Image(systemName: "align.horizontal.center.fill")
                        }
                        Button { viewModel.alignSelected(alignment: .right) } label: {
                            Image(systemName: "align.horizontal.right.fill")
                        }
                        Spacer()
                        Button { viewModel.alignSelected(alignment: .top) } label: {
                            Image(systemName: "align.vertical.top.fill")
                        }
                        Button { viewModel.alignSelected(alignment: .centerY) } label: {
                            Image(systemName: "align.vertical.center.fill")
                        }
                        Button { viewModel.alignSelected(alignment: .bottom) } label: {
                            Image(systemName: "align.vertical.bottom.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .font(.subheadline)
                }
                
                Divider()
                
                // Boolean Operations
                VStack(alignment: .leading, spacing: 10) {
                    Text("Path Boolean")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("Union") {
                            viewModel.performBoolean(operation: .union)
                        }
                        Button("Subtract") {
                            viewModel.performBoolean(operation: .subtract)
                        }
                        Button("Intersect") {
                            viewModel.performBoolean(operation: .intersect)
                        }
                        Button("Exclude") {
                            viewModel.performBoolean(operation: .exclude)
                        }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                Divider()
                
                // Cross-Workspace Actions
                VStack(spacing: 10) {
                    Button {
                        viewModel.sendToPhotoWorkspace()
                    } label: {
                        Label("Send to Photo Workspace", systemImage: "photo.badge.arrow.forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        viewModel.isExportSheetPresented = true
                    } label: {
                        Label("Export (SVG / PDF / PNG)", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(width: 280)
        .background(.regularMaterial)
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
