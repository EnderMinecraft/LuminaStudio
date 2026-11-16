import Foundation

public protocol Command: Sendable {
    var name: String { get }
    var estimatedMemoryBytes: Int { get }
    func execute() async throws
    func undo() async throws
}
