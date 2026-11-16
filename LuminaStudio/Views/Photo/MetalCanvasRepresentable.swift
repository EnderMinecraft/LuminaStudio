import SwiftUI
import CoreGraphics
import EditorCore

#if canImport(UIKit) && canImport(MetalKit)
import UIKit
import MetalKit

public struct MetalCanvasRepresentable: UIViewRepresentable {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: MetalDeviceManager.shared.device)
        mtkView.backgroundColor = .systemGray6
        mtkView.clearColor = MTLClearColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        mtkView.delegate = context.coordinator
        mtkView.isMultipleTouchEnabled = true
        mtkView.isOpaque = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        
        context.coordinator.setupGestures(on: mtkView)
        return mtkView
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.viewModel = viewModel
    }
    
    public final class Coordinator: NSObject, MTKViewDelegate {
        var viewModel: PhotoEditorViewModel
        private var initialPinchZoom: Double = 1.0
        private var initialPanOffset: CGPoint = .zero
        private var initialRotation: Double = 0.0
        
        init(viewModel: PhotoEditorViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        func setupGestures(on view: UIView) {
            // Pinch to zoom
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            view.addGestureRecognizer(pinch)
            
            // Two-finger pan
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            view.addGestureRecognizer(pan)
            
            // Two-finger rotate
            let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
            view.addGestureRecognizer(rotate)
            
            // Double-tap to fit
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            doubleTap.numberOfTouchesRequired = 1
            view.addGestureRecognizer(doubleTap)
            
            // Two-finger single tap -> Undo
            let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerTap(_:)))
            twoFingerTap.numberOfTouchesRequired = 2
            twoFingerTap.numberOfTapsRequired = 1
            view.addGestureRecognizer(twoFingerTap)
            
            // Three-finger tap -> Redo
            let threeFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap(_:)))
            threeFingerTap.numberOfTouchesRequired = 3
            threeFingerTap.numberOfTapsRequired = 1
            view.addGestureRecognizer(threeFingerTap)
        }
        
        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                initialPinchZoom = viewModel.viewport.zoom
            case .changed:
                let scale = Double(gesture.scale)
                let newZoom = initialPinchZoom * scale
                viewModel.viewport.zoom = max(ViewportState.minZoom, min(ViewportState.maxZoom, newZoom))
            default:
                break
            }
        }
        
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .began:
                initialPanOffset = viewModel.viewport.panOffset
            case .changed:
                viewModel.viewport.panOffset = CGPoint(
                    x: initialPanOffset.x + translation.x,
                    y: initialPanOffset.y + translation.y
                )
            default:
                break
            }
        }
        
        @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
            switch gesture.state {
            case .began:
                initialRotation = viewModel.viewport.rotationRadians
            case .changed:
                viewModel.viewport.rotationRadians = initialRotation + Double(gesture.rotation)
            default:
                break
            }
        }
        
        @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            viewModel.zoomToFit(containerSize: view.bounds.size)
        }
        
        @objc private func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
            viewModel.undo()
        }
        
        @objc private func handleThreeFingerTap(_ gesture: UITapGestureRecognizer) {
            viewModel.redo()
        }
        
        // MARK: - MTKViewDelegate
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewModel.viewport.viewportSize = size
            if viewModel.viewport.panOffset == .zero {
                viewModel.zoomToFit(containerSize: size)
            }
        }
        
        public func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandQueue = MetalDeviceManager.shared.commandQueue,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }
            
            // Clear render pass
            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                encoder.endEncoding()
            }
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
#else
// Fallback for previews and headless environments
public struct MetalCanvasRepresentable: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public var body: some View {
        ZStack {
            Color(white: 0.15)
            VStack(spacing: 8) {
                Image(systemName: "photo.artframe")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("\(viewModel.document.title) (\(viewModel.document.configuration.width) × \(viewModel.document.configuration.height))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Zoom: \(Int(viewModel.viewport.zoom * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
#endif
