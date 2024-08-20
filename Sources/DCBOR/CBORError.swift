import Foundation

/// An error decoding or parsing CBOR.
public enum CBORError: LocalizedError, Equatable {
    /// Early end of data.
    case underrun

    /// Unsupported value in CBOR header.
    ///
    /// The case includes the encountered header as associated data.
    case badHeaderValue(encountered: UInt8)
    
    /// A numeric value was encoded in non-canonical form.
    case nonCanonicalNumeric
    
    /// An invalid simple value was encountered.
    case invalidSimple

    /// An invalidly-encoded UTF-8 string was encountered.
    case invalidString
    
    /// A string was not in Unicode Normalization Form C.
    case nonCanonicalString

    /// The decoded CBOR had extra data at the end.
    ///
    /// The case includes the number of unused bytes as associated data.
    case unusedData(Int)

    /// The decoded CBOR map has keys that are not in canonical order.
    case misorderedMapKey

    /// The decoded CBOR map has a duplicate key.
    case duplicateMapKey

    /// The numeric value could not be represented in the specified numeric type.
    case outOfRange

    /// The decoded value was not the expected type.
    case wrongType

    /// The decoded value did not have the expected tag.
    ///
    /// The case includes the expected tag and encountered tag as associated data.
    case wrongTag(expected: Tag, encountered: Tag)
    
    /// Invalid CBOR format. Frequently thrown by libraries depending on this one.
    case invalidFormat
}
