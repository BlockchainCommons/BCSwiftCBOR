import Foundation
import OrderedCollections
import WolfBase

/// A symbolic representation of CBOR data.
public indirect enum CBOR {
    /// Unsigned integer (major type 0).
    case unsigned(UInt64)
    /// Negative integer (major type 1).
    case negative(Int64)
    /// Byte string (major type 2).
    case bytes(Data)
    /// UTF-8 string (major type 3).
    case text(String)
    /// Array (major type 4).
    case array([CBOR])
    /// Map (major type 5).
    case map(Map)
    /// Tagged value (major type 6).
    case tagged(Tag, CBOR)
    /// Simple value (majory type 7).
    case value(Value)
}

public extension CBOR {
    /// The CBOR symbolic value for `false`.
    static var `false` = Value(20).cbor
    /// The CBOR symbolic value for `true`.
    static var `true` = Value(21).cbor
    /// The CBOR symbolic value for `null` (`nil`).
    static var null = Value(22).cbor

    /// Creates the symbolic CBOR representation of a value conforming to ``CBOREncodable``.
    init<T>(_ x: T) where T: CBOREncodable {
        self = x.cbor
    }
}

extension CBOR: CBOREncodable {
    public var cbor: CBOR {
        self
    }

    public func encodeCBOR() -> Data {
        switch self {
        case .unsigned(let x):
            return x.encodeCBOR()
        case .negative(let x):
            precondition(x < 0)
            return x.encodeCBOR()
        case .bytes(let x):
            return x.encodeCBOR()
        case .text(let x):
            return x.encodeCBOR()
        case .array(let x):
            return x.encodeCBOR()
        case .map(let x):
            return x.encodeCBOR()
        case .tagged(let tag, let item):
            return tag.value.encodeVarInt(.tagged) + item.encodeCBOR()
        case .value(let x):
            return x.encodeCBOR()
        }
    }
}

extension CBOR: Equatable {
    public static func ==(lhs: CBOR, rhs: CBOR) -> Bool {
        switch (lhs, rhs) {
        case (CBOR.unsigned(let l), CBOR.unsigned(let r)): return l == r
        case (CBOR.negative(let l), CBOR.negative(let r)): return l == r
        case (CBOR.bytes(let l), CBOR.bytes(let r)): return l == r
        case (CBOR.text(let l), CBOR.text(let r)): return l == r
        case (CBOR.array(let l), CBOR.array(let r)): return l == r
        case (CBOR.map(let l), CBOR.map(let r)): return l == r
        case (CBOR.tagged(let ltag, let litem), CBOR.tagged(let rtag, let ritem)): return ltag == rtag && litem == ritem
        case (CBOR.value(let l), CBOR.value(let r)): return l == r
        default: return false
        }
    }
}

extension CBOR: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unsigned(let x):
            return x.description
        case .negative(let x):
            return x.description
        case .bytes(let x):
            return x.hex.flanked("h'", "'")
        case .text(let x):
            return x.description.flanked("\"")
        case .array(let x):
            return x.map({ $0.description }).joined(separator: ", ").flanked("[", "]")
        case .map(let x):
            return x.description
        case .tagged(let tag, let item):
            return "\(tag)(\(item))"
        case .value(let x):
            return x.description
        }
    }
}

extension CBOR: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unsigned(let x):
            return "unsigned(\(x))"
        case .negative(let x):
            return "negative(\(x))"
        case .bytes(let x):
            return "bytes(\(x.hex))"
        case .text(let x):
            return "text(\(x.flanked("\"")))"
        case .array(let x):
            return "array(\(x))"
        case .map(let x):
            return "map(\(x.debugDescription))"
        case .tagged(let tag, let item):
            return "tagged(\(tag), \(item.debugDescription))"
        case .value(let x):
            return "value(\(x.debugDescription))"
        }
    }
}

public extension CBOR {
    /// Decode CBOR binary representation to symbolic representation.
    ///
    /// Throws an error if the data is not well-formed deterministic CBOR.
    init(_ data: Data) throws {
        self = try decodeCBOR(data)
    }
    
    /// Represent a `Data` object as CBOR bytes.
    init(bytes: Data) {
        self = .bytes(bytes)
    }
}

extension CBOR: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = value ? Self.true : Self.false
    }
}

extension CBOR: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = CBOR.null
    }
}

extension CBOR: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = value.cbor
    }
}

extension CBOR: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = value.cbor
    }
}

extension CBOR: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CBOREncodable...) {
        self = (elements.map { $0.cbor }).cbor
    }
}

extension CBOR: DataProvider {
    public var providedData: Data {
        encodeCBOR()
    }
}
