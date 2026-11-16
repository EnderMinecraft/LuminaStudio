import Foundation

public final class TileCache<Key: Hashable, Value>: @unchecked Sendable {
    private final class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    private let lock = NSLock()
    private var capacity: Int
    private var map: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    
    public init(capacity: Int = 256) {
        self.capacity = max(1, capacity)
    }
    
    public func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = map[key] else { return nil }
        moveToHead(node)
        return node.value
    }
    
    public func set(_ value: Value, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = map[key] {
            existing.value = value
            moveToHead(existing)
            return
        }
        
        let node = Node(key: key, value: value)
        map[key] = node
        addToHead(node)
        
        if map.count > capacity {
            removeTail()
        }
    }
    
    public func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = map.removeValue(forKey: key) else { return }
        removeNode(node)
    }
    
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        map.removeAll()
        head = nil
        tail = nil
    }
    
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return map.count
    }
    
    // MARK: - Private Doubly Linked List Operations
    
    private func addToHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }
    
    private func moveToHead(_ node: Node) {
        guard node !== head else { return }
        removeNode(node)
        addToHead(node)
    }
    
    private func removeNode(_ node: Node) {
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        node.prev = nil
        node.next = nil
    }
    
    private func removeTail() {
        guard let oldTail = tail else { return }
        map.removeValue(forKey: oldTail.key)
        removeNode(oldTail)
    }
}
