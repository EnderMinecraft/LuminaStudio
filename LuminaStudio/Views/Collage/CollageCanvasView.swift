import SwiftUI
import CoreGraphics
import CollageCore

public struct CollageCanvasView: View {
    @Bindable var viewModel: CollageEditorViewModel
    
    public init(viewModel: CollageEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let canvasFrame = calculateCanvasFrame(in: geometry.size)
            
            ZStack {
                // Workspace background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Collage Canvas Box
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: viewModel.document.backgroundColorHex) ?? .white)
                        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                    
                    // Layout Resolution
                    let (cells, dividers) = BSPLayoutSolver.shared.solve(
                        node: viewModel.document.rootNode,
                        in: CGRect(origin: .zero, size: canvasFrame.size),
                        spacing: viewModel.document.cellSpacing,
                        margin: viewModel.document.outerMargin
                    )
                    
                    // Render Solved Cells
                    ForEach(Array(cells.enumerated()), id: \.element.cellID) { idx, item in
                        SolvedCellView(
                            item: item,
                            index: idx,
                            cornerRadius: item.cell.customCornerRadius ?? viewModel.document.cornerRadius,
                            isSelected: viewModel.selectedCellID == item.cellID
                        )
                        .frame(width: item.rect.width, height: item.rect.height)
                        .position(x: item.rect.midX, y: item.rect.midY)
                        .onTapGesture {
                            viewModel.selectCell(item.cellID)
                        }
                    }
                    
                    // Render Interactive Dividers
                    ForEach(dividers, id: \.splitID) { divider in
                        DividerHandleView(
                            divider: divider,
                            isDragging: viewModel.draggingDividerID == divider.splitID
                        )
                        .frame(width: max(24, divider.rect.width), height: max(24, divider.rect.height))
                        .position(x: divider.rect.midX, y: divider.rect.midY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    viewModel.draggingDividerID = divider.splitID
                                    let newRatio = calculateRatio(
                                        translation: value.translation,
                                        divider: divider,
                                        canvasSize: canvasFrame.size
                                    )
                                    viewModel.updateDividerRatio(splitID: divider.splitID, newRatio: newRatio)
                                }
                                .onEnded { _ in
                                    viewModel.finishDividerDrag()
                                }
                        )
                    }
                    
                    // Magnetic Snap Ratio Feedback Pill
                    if let pill = viewModel.snappedRatioPill {
                        Text(pill)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: canvasFrame.width, height: canvasFrame.height)
                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
            }
        }
    }
    
    // MARK: - Geometry & Ratio Calculations
    
    private func calculateCanvasFrame(in containerSize: CGSize) -> CGRect {
        let preset = viewModel.document.aspectRatioPreset
        let aspect: CGFloat
        switch preset {
        case .square: aspect = 1.0
        case .story: aspect = 9.0 / 16.0
        case .portrait: aspect = 4.0 / 5.0
        case .landscape: aspect = 16.0 / 9.0
        case .a4: aspect = 210.0 / 297.0
        }
        
        let maxW = containerSize.width * 0.85
        let maxH = containerSize.height * 0.82
        
        var w = maxW
        var h = w / aspect
        if h > maxH {
            h = maxH
            w = h * aspect
        }
        return CGRect(x: 0, y: 0, width: w, height: h)
    }
    
    private func calculateRatio(translation: CGSize, divider: SolvedDivider, canvasSize: CGSize) -> Double {
        switch divider.direction {
        case .vertical:
            let delta = translation.width / canvasSize.width
            return max(0.1, min(0.9, divider.currentRatio + Double(delta)))
        case .horizontal:
            let delta = translation.height / canvasSize.height
            return max(0.1, min(0.9, divider.currentRatio + Double(delta)))
        }
    }
}

// MARK: - Subviews

private struct SolvedCellView: View {
    let item: SolvedCellLayout
    let index: Int
    let cornerRadius: CGFloat
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Elegant gradient fill for cell
            let colors = palette(for: index)
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // Cell Label / Rotation badge
            VStack(spacing: 4) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: min(32, item.rect.width * 0.2)))
                    .foregroundStyle(.white.opacity(0.85))
                Text("Cell \(index + 1)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                if item.cell.rotationQuarterTurns > 0 {
                    Text("\(item.cell.rotationQuarterTurns * 90)°")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .rotationEffect(.degrees(Double(item.cell.rotationQuarterTurns * 90)))
            .scaleEffect(x: item.cell.isFlippedHorizontally ? -1 : 1, y: item.cell.isFlippedVertically ? -1 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
    }
    
    private func palette(for i: Int) -> [Color] {
        let pairs: [[Color]] = [
            [.blue, .indigo],
            [.teal, .cyan],
            [.orange, .red],
            [.purple, .pink],
            [.green, .mint],
            [.yellow, .orange]
        ]
        return pairs[i % pairs.count]
    }
}

private struct DividerHandleView: View {
    let divider: SolvedDivider
    let isDragging: Bool
    
    var body: some View {
        ZStack {
            // Hit region
            Color.clear
            
            // Visual pill handle
            Capsule()
                .fill(isDragging ? Color.accentColor : Color.gray.opacity(0.6))
                .frame(
                    width: divider.direction == .vertical ? 5 : 44,
                    height: divider.direction == .vertical ? 44 : 5
                )
                .shadow(radius: isDragging ? 3 : 1)
        }
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
}
