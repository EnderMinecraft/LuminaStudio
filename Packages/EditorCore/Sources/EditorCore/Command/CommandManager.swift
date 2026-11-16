import Foundation

public struct HistoryEntry: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let timestamp: Date
    public let isCurrent: Bool
    
    public init(id: UUID = UUID(), name: String, timestamp: Date = Date(), isCurrent: Bool = false) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.isCurrent = isCurrent
    }
}

public final class CommandManager: @unchecked Sendable {
    private let lock = NSLock()
    private var undoStack: [any Command] = []
    private var redoStack: [any Command] = []
    public var maxHistoryCount: Int
    
    public init(maxHistoryCount: Int = 50) {
        self.maxHistoryCount = maxHistoryCount
    }
    
    public var canUndo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !undoStack.isEmpty
    }
    
    public var canRedo: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !redoStack.isEmpty
    }
    
    public var undoCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return undoStack.count
    }
    
    public var redoCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return redoStack.count
    }
    
    public func execute(_ command: any Command) async throws {
        try await command.execute()
        lock.lock()
        undoStack.append(command)
        redoStack.removeAll()
        if undoStack.count > maxHistoryCount {
            undoStack.removeFirst()
        }
        lock.unlock()
    }
    
    public func undo() async throws {
        let commandToUndo: (any Command)? = {
            lock.lock()
            defer { lock.unlock() }
            guard let last = undoStack.popLast() else { return nil }
            return last
        }()
        
        guard let command = commandToUndo else { return }
        try await command.undo()
        
        lock.lock()
        redoStack.append(command)
        lock.unlock()
    }
    
    public func redo() async throws {
        let commandToRedo: (any Command)? = {
            lock.lock()
            defer { lock.unlock() }
            guard let last = redoStack.popLast() else { return nil }
            return last
        }()
        
        guard let command = commandToRedo else { return }
        try await command.execute()
        
        lock.lock()
        undoStack.append(command)
        lock.unlock()
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    public func historyEntries() -> [HistoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        
        var list: [HistoryEntry] = []
        for (i, cmd) in undoStack.enumerated() {
            let isCurrent = (i == undoStack.count - 1)
            list.append(HistoryEntry(name: cmd.name, isCurrent: isCurrent))
        }
        for cmd in redoStack.reversed() {
            list.append(HistoryEntry(name: cmd.name, isCurrent: false))
        }
        return list
    }
}
