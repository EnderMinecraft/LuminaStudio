import Foundation
import SwiftUI
import Observation
import EditorCore
import VectorCore
import CollageCore

public enum WorkspaceMode: String, CaseIterable, Identifiable, Sendable {
    case photo = "Photo"
    case vector = "Vector"
    case collage = "Collage"
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .photo: return "photo.fill"
        case .vector: return "point.topleft.down.curvedto.point.bottomright.up"
        case .collage: return "rectangle.split.2x2.fill"
        }
    }
}

@Observable
public final class RootCoordinator: @unchecked Sendable {
    public var activeWorkspace: WorkspaceMode = .photo
    
    // Independent Documents preserved across switches
    public var photoDocument: LuminaDocument
    public var vectorDocument: VectorDocument
    public var collageDocument: CollageDocument
    
    // Command Managers per workspace
    public let photoCommandManager: CommandManager
    public let vectorCommandManager: CommandManager
    public let collageCommandManager: CommandManager
    
    public init() {
        self.photoDocument = LuminaDocument(title: "Untitled Photo")
        self.vectorDocument = VectorDocument(title: "Untitled Vector")
        self.collageDocument = CollageDocument(title: "Untitled Collage")
        
        self.photoCommandManager = CommandManager()
        self.vectorCommandManager = CommandManager()
        self.collageCommandManager = CommandManager()
    }
    
    public func switchWorkspace(to mode: WorkspaceMode) {
        activeWorkspace = mode
    }
}
