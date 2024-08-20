import Foundation

func decodeCBOR(_ data: Data) throws -> CBOR {
    let (cbor, len) = try decodeCBORInternal(ArraySlice(data))
    let remaining = data.count - len
    guard remaining == 0 else {
        throw CBORError.unusedData(remaining)
    }
    return cbor
}

extension ArraySlice where Element == UInt8 {
    func at(_ index: Int) -> UInt8 {
        self[startIndex + index]
    }
    
    func from(_ index: Int) -> ArraySlice<UInt8> {
        self[(startIndex + index)...]
    }
    
    func range(_ range: Range<Int>) -> ArraySlice<UInt8> {
        self[(startIndex + range.lowerBound)..<(startIndex + range.upperBound)]
    }
}

func parseHeader(_ header: UInt8) -> (MajorType, UInt8) {
    let majorType: MajorType
    switch header >> 5 {
    case 0:
        majorType = .unsigned
    case 1:
        majorType = .negative
    case 2:
        majorType = .bytes
    case 3:
        majorType = .text
    case 4:
        majorType = .array
    case 5:
        majorType = .map
    case 6:
        majorType = .tagged
   case 7:
        majorType = .simple
    default:
        preconditionFailure()
    }
    let headerValue = header & 31
    return (majorType, headerValue)
}

func parseHeaderVarint(_ data: ArraySlice<UInt8>) throws -> (majorType: MajorType, value: UInt64, varIntLen: Int) {
    guard !data.isEmpty else {
        throw CBORError.underrun
    }
    
    let header = data.at(0)
    let (majorType, headerValue) = parseHeader(header)
    let dataRemaining = data.count - 1
    let value: UInt64
    let varIntLen: Int
    switch headerValue {
    case 0...23:
        value = UInt64(headerValue)
        varIntLen = 1
    case 24:
        guard dataRemaining >= 1 else {
            throw CBORError.underrun
        }
        value = UInt64(data.at(1))
        guard value >= 24 else {
            throw CBORError.nonCanonicalNumeric
        }
        varIntLen = 2
    case 25:
        guard dataRemaining >= 2 else {
            throw CBORError.underrun
        }
        value =
            UInt64(data.at(1)) << 8 |
            UInt64(data.at(2))
        guard value > UInt8.max || header == 0xf9 else {
            throw CBORError.nonCanonicalNumeric
        }
        varIntLen = 3
    case 26:
        guard dataRemaining >= 4 else {
            throw CBORError.underrun
        }
        value =
            UInt64(data.at(1)) << 24 |
            UInt64(data.at(2)) << 16 |
            UInt64(data.at(3)) << 8 |
            UInt64(data.at(4))
        guard value > UInt16.max || header == 0xfa else {
            throw CBORError.nonCanonicalNumeric
        }
        varIntLen = 5
    case 27:
        guard dataRemaining >= 8 else {
            throw CBORError.underrun
        }
        let valHi =
            UInt64(data.at(1)) << 56 |
            UInt64(data.at(2)) << 48 |
            UInt64(data.at(3)) << 40 |
            UInt64(data.at(4)) << 32
        
        let valLo =
            UInt64(data.at(5)) << 24 |
            UInt64(data.at(6)) << 16 |
            UInt64(data.at(7)) << 8 |
            UInt64(data.at(8))
        
        value = valHi | valLo
        
        guard value > UInt32.max || header == 0xfb else {
            throw CBORError.nonCanonicalNumeric
        }
        varIntLen = 9
    default:
        throw CBORError.badHeaderValue(encountered: headerValue)
    }
    return (majorType, value, varIntLen)
}

func parseBytes(_ data: ArraySlice<UInt8>, len: Int) throws -> ArraySlice<UInt8> {
    guard data.count >= len else {
        throw CBORError.underrun
    }
    return data.range(0..<len)
}

func decodeCBORInternal(_ data: ArraySlice<UInt8>) throws -> (cbor: CBOR, len: Int) {
    guard !data.isEmpty else {
        throw CBORError.underrun
    }
    let (majorType, value, headerVarIntLen) = try parseHeaderVarint(data)
    switch majorType {
    case .unsigned:
        return (.unsigned(value), headerVarIntLen)
    case .negative:
        return (.negative(value), headerVarIntLen)
    case .bytes:
        let dataLen = Int(value)
        let buf = try parseBytes(data.from(headerVarIntLen), len: dataLen)
        let bytes = Data(buf)
        return (bytes.cbor, headerVarIntLen + dataLen)
    case .text:
        let dataLen = Int(value)
        let buf = try parseBytes(data.from(headerVarIntLen), len: dataLen)
        guard let string = String(bytes: buf, encoding: .utf8) else {
            throw CBORError.invalidString
        }
        let normalizedString = string.precomposedStringWithCanonicalMapping
        guard let normalizedBuf = normalizedString.data(using: .utf8) else {
            throw CBORError.invalidString
        }
        guard ArraySlice(normalizedBuf) == buf else {
            throw CBORError.nonCanonicalString
        }
        return (normalizedString.cbor, headerVarIntLen + dataLen)
    case .array:
        var pos = headerVarIntLen
        var items: [CBOR] = []
        for _ in 0..<value {
            let (item, itemLen) = try decodeCBORInternal(data.from(pos))
            items.append(item)
            pos += itemLen
        }
        return (items.cbor, pos)
    case .map:
        var pos = headerVarIntLen
        var map = Map()
        for _ in 0..<value {
            let (key, keyLen) = try decodeCBORInternal(data.from(pos))
            pos += keyLen
            let (value, valueLen) = try decodeCBORInternal(data.from(pos))
            pos += valueLen
            try map.insertNext(key, value)
        }
        return (map.cbor, pos)
    case .tagged:
        let (item, itemLen) = try decodeCBORInternal(data.from(headerVarIntLen))
        return (CBOR.tagged(Tag(value), item), headerVarIntLen + itemLen)
    case .simple:
        switch headerVarIntLen {
        case 3:
            let f = CBORFloat16(bitPattern: UInt16(value))
            try f.validateCanonical()
            return (f.cbor, headerVarIntLen)
        case 5:
            let f = Float(bitPattern: UInt32(value))
            try f.validateCanonical()
            return (f.cbor, headerVarIntLen)
        case 9:
            let f = Double(bitPattern: value)
            try f.validateCanonical()
            return (f.cbor, headerVarIntLen)
        default:
            switch value {
            case 20:
                return (CBOR.false, headerVarIntLen)
            case 21:
                return (CBOR.true, headerVarIntLen)
            case 22:
                return (CBOR.null, headerVarIntLen)
            default:
                throw CBORError.invalidSimple
                //return (Simple.value(value).cbor, headerVarIntLen)
            }
        }
    }
}
