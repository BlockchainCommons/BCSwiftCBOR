import Foundation
import NumberKit

/// A symbolic representation of CBOR data.
public indirect enum CBOR: Sendable {
    /// Unsigned integer (major type 0).
    case unsigned(UInt64)
    /// Negative integer (major type 1).
    ///
    /// value = (-n) - 1
    case negative(UInt64)
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
    /// Simple value (major type 7).
    case simple(Simple)
}

public extension CBOR {
    /// The CBOR symbolic value for `false`.
    static let `false` = Bool.cborFalse
    /// The CBOR symbolic value for `true`.
    static let `true` = Bool.cborTrue
    /// The CBOR symbolic value for `null` (`nil`).
    static let null = Simple.null.cbor

    /// Creates the symbolic CBOR representation of a value conforming to ``CBOREncodable``.
    init<T>(_ x: T) where T: CBOREncodable {
        self = x.cbor
    }
}

extension CBOR: CBOREncodable {
    public var cbor: CBOR {
        self
    }

    public var cborData: Data {
        switch self {
        case .unsigned(let x):
            return x.cborData
        case .negative(let x):
            return x.encodeVarInt(.negative)
        case .bytes(let x):
            return x.cborData
        case .text(let x):
            return x.cborData
        case .array(let x):
            return x.cborData
        case .map(let x):
            return x.cborData
        case .tagged(let tag, let item):
            return tag.value.encodeVarInt(.tagged) + item.cborData
        case .simple(let x):
            return x.cborData
        }
    }
}

extension CBOR: CBORDecodable {
    public init(cbor: CBOR) throws {
        self = cbor
    }
}

extension CBOR: CBORCodable { }

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
        case (CBOR.simple(let l), CBOR.simple(let r)): return l == r
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
            return (-BigInt(x) - 1).description
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
        case .simple(let x):
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
            return "negative(\(-1 - BigInt(x)))"
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
        case .simple(let x):
            return "simple(\(x.debugDescription))"
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
