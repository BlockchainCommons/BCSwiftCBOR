import Foundation

extension String: CBORCodable {
    public var cbor: CBOR {
        .text(self)
    }
    
    public var cborData: Data {
        let nfcNormalizedString = self.precomposedStringWithCanonicalMapping
        let data = Data(nfcNormalizedString.utf8)
        return data.count.encodeVarInt(.text) + data
    }
    
    public init(cbor: CBOR) throws {
        switch cbor {
        case .text(let string):
            self = string
        default:
            throw CBORError.wrongType
        }
    }
}
