import Foundation
import SortedCollections

/// A CBOR map with Copy-on-Write semantics.
///
/// Keys are kept sorted by encoded CBOR form in ascending lexicographic order.
public struct Map: Sendable {
    private final class Storage: Sendable {
        let dict: SortedDictionary<MapKey, MapValue>
        
        init() {
            self.dict = .init()
        }
        
        init(_ dict: SortedDictionary<MapKey, MapValue>) {
            self.dict = dict
        }
    }
    
    private var storage: Storage
    
    /// Creates a new empty CBOR map.
    public init() {
        self.storage = Storage()
    }
    
    /// Creates a new CBOR map from the provided sequence of key-value pairs.
    public init<S>(_ elements: S) where S: Sequence, S.Element == (any CBOREncodable, any CBOREncodable) {
        var dict = SortedDictionary<MapKey, MapValue>()
        for (k, v) in elements {
            dict[MapKey(k)] = MapValue(key: k.cbor, value: v.cbor)
        }
        self.storage = Storage(dict)
    }
    
    private mutating func uniqueStorage() -> SortedDictionary<MapKey, MapValue> {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.dict)
        }
        return storage.dict
    }
    
    /// Inserts a key-value pair into the map.
    public mutating func insert<K, V>(_ key: K, _ value: V) where K: CBOREncodable, V: CBOREncodable {
        var dict = uniqueStorage()
        dict[MapKey(key)] = MapValue(key: key.cbor, value: value.cbor)
        storage = Storage(dict)
    }
    
    /// Removes the specified key from the map, returning the removed value if any.
    public mutating func remove<K>(_ key: K) -> CBOR? where K: CBOREncodable {
        var dict = uniqueStorage()
        let value = dict.removeValue(forKey: MapKey(key))
        storage = Storage(dict)
        return value?.value
    }
    
    /// Returns the number of entries in the map.
    public var count: Int { storage.dict.count }
    
    /// Returns an array of all the key-value pairs in the map.
    public var entries: [(key: CBOR, value: CBOR)] {
        storage.dict.map { ($1.key, $1.value) }
    }
    
    mutating func insertNext<K, V>(_ key: K, _ value: V) throws where K: CBOREncodable, V: CBOREncodable {
        var dict = uniqueStorage()
        guard let lastEntry = dict.last else {
            self.insert(key, value)
            return
        }
        let newKey = MapKey(key)
        guard dict[newKey] == nil else {
            throw CBORError.duplicateMapKey
        }
        let entryKey = lastEntry.key
        guard entryKey < newKey else {
            throw CBORError.misorderedMapKey
        }
        dict[newKey] = MapValue(key: key.cbor, value: value.cbor)
        storage = Storage(dict)
    }

    struct MapValue: Equatable, Sendable {
        let key: CBOR
        let value: CBOR
    }

    struct MapKey: Comparable, Sendable {
        let keyData: Data
        
        init(_ keyData: Data) {
            self.keyData = keyData
        }
        
        init<T>(_ k: T) where T: CBOREncodable {
            self.init(k.cborData)
        }
        
        static func < (lhs: MapKey, rhs: MapKey) -> Bool {
            lhs.keyData.lexicographicallyPrecedes(rhs.keyData)
        }
    }
    
    public func get<K>(_ key: K) -> CBOR? where K: CBOREncodable {
        storage.dict[MapKey(key)]?.value
    }
    
    /// Gets or sets the value for the given key.
    public subscript<K, V>(key: K) -> V? where K: CBOREncodable, V: CBORCodable {
        get {
            try? V(cbor: storage.dict[MapKey(key)]?.value)
        }
        
        set {
            if let newValue {
                insert(key, newValue)
            } else {
                _ = remove(key)
            }
        }
    }
}

extension Map: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (CBOREncodable, CBOREncodable)...) {
        self.init(elements)
    }
}

extension Map: Sequence {
    public func makeIterator() -> Iterator {
        return Iterator(storage.dict)
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = (CBOR, CBOR)
        var iter: SortedDictionary<MapKey, MapValue>.Iterator
        
        init(_ dict: SortedDictionary<MapKey, MapValue>) {
            self.iter = dict.makeIterator()
        }
        
        public mutating func next() -> (CBOR, CBOR)? {
            guard let v = iter.next() else {
                return nil
            }
            return (v.value.key, v.value.value)
        }
    }
}

extension Map.MapKey: CustomDebugStringConvertible {
    var debugDescription: String {
        "0x" + keyData.hex
    }
}

extension Map: CBORCodable {
    public var cbor: CBOR {
        .map(self)
    }
    
    public var cborData: Data {
        let pairs = self.storage.dict.map { (key: MapKey, value: MapValue) in
            (key, value.value.cborData)
        }
        var buf = pairs.count.encodeVarInt(.map)
        for pair in pairs {
            buf += pair.0.keyData
            buf += pair.1
        }
        return buf
    }
    
    public init(cbor: CBOR) throws {
        switch cbor {
        case .map(let map):
            self = map
        default:
            throw CBORError.wrongType
        }
    }
}

extension Map: CustomDebugStringConvertible {
    public var debugDescription: String {
        storage.dict.map { (k, v) in
            "\(k.debugDescription): (\(v.key.debugDescription), \(v.value.debugDescription))"
        }.joined(separator: ", ")
            .flanked("{", "}")
    }
}

extension Map: CustomStringConvertible {
    public var description: String {
        storage.dict.map { (k, v) in
            "\(v.key): \(v.value)"
        }.joined(separator: ", ")
            .flanked("{", "}")
    }
}

extension Map: Equatable {
    public static func == (lhs: Map, rhs: Map) -> Bool {
        lhs.storage.dict == rhs.storage.dict
    }
}
