import Foundation
import NumberKit

let cborNaN = Data([0xf9, 0x7e, 0x00])

extension Double: CBORCodable {
    public var cbor: CBOR {
        if
            self < 0,
            let n = BigInt(exactly: self),
            let i = UInt64(exactly: -1 - n)
        {
            return .negative(i)
        }
        if let i = UInt64(exactly: self) {
            return i.cbor
        }
        return .simple(.float(self))
    }
    
    public init(cbor: CBOR) throws {
        switch cbor {
        case .unsigned(let n):
            guard let f = Double(exactly: n) else {
                throw CBORError.outOfRange
            }
            self = f
        case .negative(let n):
            let b = -1 - BigInt(n)
            guard let f = Double(exactly: b) else {
                throw CBORError.outOfRange
            }
            self = f
        case .simple(let simple):
            guard case .float(let f) = simple else {
                throw CBORError.wrongType
            }
            self = f
        default:
            throw CBORError.wrongType
        }
    }
    
    public var cborData: Data {
        let f = Float(self)
        guard self != Double(f) else {
            return f.cborData
        }
        if
            self < 0,
            let i = Int64(exactly: self)
        {
            return i.cborData
        }
        if let i = UInt64(exactly: self) {
            return i.cborData
        }
        guard !isNaN else {
            return cborNaN
        }
        return self.bitPattern.encodeInt(.simple)
    }
    
    func validateCanonical() throws {
        guard
            self != Double(Float(self)),
            Int64(exactly: self) == nil,
            !isNaN
        else {
            throw CBORError.nonCanonicalNumeric
        }
    }
}

extension Float: CBORCodable {
    public var cbor: CBOR {
        if
            self < 0,
            let n = BigInt(exactly: self),
            let i = UInt64(exactly: -1 - n)
        {
            return .negative(i)
        }
        if let i = UInt64(exactly: self) {
            return i.cbor
        }
        return .simple(.float(Double(self)))
    }
    
    public init(cbor: CBOR) throws {
        switch cbor {
        case .unsigned(let n):
            guard let f = Float(exactly: n) else {
                throw CBORError.outOfRange
            }
            self = f
        case .negative(let n):
            let b = -1 - BigInt(n)
            guard let f = Float(exactly: b) else {
                throw CBORError.outOfRange
            }
            self = f
        case .simple(let simple):
            guard case .float(let f) = simple else {
                throw CBORError.wrongType
            }
            guard let f = Float(exactly: f) else {
                throw CBORError.outOfRange
            }
            self = f
        default:
            throw CBORError.wrongType
        }
    }

    public var cborData: Data {
        let f = CBORFloat16(self)
        guard self != Float(f) else {
            return f.cborData
        }
        if
            self < 0,
            let i = Int64(exactly: self)
        {
            return i.cborData
        }
        if let i = UInt64(exactly: self) {
            return i.cborData
        }
        guard !isNaN else {
            return cborNaN
        }
        return self.bitPattern.encodeInt(.simple)
    }
    
    func validateCanonical() throws {
        guard
            self != Float(CBORFloat16(self)),
            Int64(exactly: self) == nil,
            !isNaN
        else {
            throw CBORError.nonCanonicalNumeric
        }
    }
}

extension CBORFloat16: CBORCodable {
    public var cbor: CBOR {
        if
            Float(self) < 0,
            let i = Int64(exactly: self)
        {
            return i.cbor
        }
        if let i = UInt64(exactly: self) {
            return i.cbor
        }
        return .simple(.float(Double(self)))
    }
    
    public init(cbor: CBOR) throws {
        switch cbor {
        case .unsigned(let n):
            guard let f = CBORFloat16(exactly: n) else {
                throw CBORError.outOfRange
            }
            self = f
        case .negative(let n):
            let b = -1 - BigInt(n)
            guard
                let n = Int64(exactly: b),
                let f = CBORFloat16(exactly: n)
            else {
                throw CBORError.outOfRange
            }
            self = f
        case .simple(let simple):
            guard case .float(let f) = simple else {
                throw CBORError.wrongType
            }
            guard let f = CBORFloat16(exactly: f) else {
                throw CBORError.outOfRange
            }
            self = f
        default:
            throw CBORError.wrongType
        }
    }

    public var cborData: Data {
        if
            Float(self) < 0,
            let i = Int64(exactly: self)
        {
            return i.cborData
        }
        if let i = UInt64(exactly: self) {
            return i.cborData
        }
        guard !isNaN else {
            return cborNaN
        }
        return self.bitPattern.encodeInt(.simple)
    }
    
    func validateCanonical() throws {
        guard
            Int64(exactly: self) == nil,
            !isNaN || self.bitPattern == 0x7e00
        else {
            throw CBORError.nonCanonicalNumeric
        }
    }
}
