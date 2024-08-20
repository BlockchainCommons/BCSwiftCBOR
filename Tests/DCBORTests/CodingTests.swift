import XCTest
import WolfBase
import DCBOR

final class CodingTests: XCTestCase {
    func runTest<T>(_ t: T, _ expectedDebugDescription: String, _ expectedDescription: String, _ expectedData: String) where T: CBORCodable & Equatable {
        let cbor = t.cbor
        XCTAssertEqual(cbor.debugDescription, expectedDebugDescription)
        XCTAssertEqual(cbor.description, expectedDescription)
        let data = cbor.cborData
        XCTAssertEqual(data.hex, expectedData.lowercased())
        let decodedCBOR = try! CBOR(data)
        XCTAssertEqual(cbor, decodedCBOR)
        let decodedT = try! T(cbor: cbor)
        XCTAssertEqual(t, decodedT)
    }
    
    func runTestDecode(_ data: Data, _ expectedDebugDescription: String, _ expectedDescription: String) {
        let decodedCBOR = try! CBOR(data)
        XCTAssertEqual(decodedCBOR.debugDescription, expectedDebugDescription)
        XCTAssertEqual(decodedCBOR.description, expectedDescription)
    }

    func testUnsigned() throws {
        runTest(UInt8 (0), "unsigned(0)", "0", "00")
        runTest(UInt16(0), "unsigned(0)", "0", "00")
        runTest(UInt32(0), "unsigned(0)", "0", "00")
        runTest(UInt64(0), "unsigned(0)", "0", "00")
        runTest(UInt  (0), "unsigned(0)", "0", "00")

        runTest(UInt8 (1), "unsigned(1)", "1", "01")
        runTest(UInt16(1), "unsigned(1)", "1", "01")
        runTest(UInt32(1), "unsigned(1)", "1", "01")
        runTest(UInt64(1), "unsigned(1)", "1", "01")
        runTest(UInt  (1), "unsigned(1)", "1", "01")

        runTest(UInt8 (23), "unsigned(23)", "23", "17")
        runTest(UInt16(23), "unsigned(23)", "23", "17")
        runTest(UInt32(23), "unsigned(23)", "23", "17")
        runTest(UInt64(23), "unsigned(23)", "23", "17")
        runTest(UInt  (23), "unsigned(23)", "23", "17")

        runTest(UInt8 (24), "unsigned(24)", "24", "1818")
        runTest(UInt16(24), "unsigned(24)", "24", "1818")
        runTest(UInt32(24), "unsigned(24)", "24", "1818")
        runTest(UInt64(24), "unsigned(24)", "24", "1818")
        runTest(UInt  (24), "unsigned(24)", "24", "1818")

        runTest(UInt8       .max,  "unsigned(255)", "255", "18ff")
        runTest(UInt16(UInt8.max), "unsigned(255)", "255", "18ff")
        runTest(UInt32(UInt8.max), "unsigned(255)", "255", "18ff")
        runTest(UInt64(UInt8.max), "unsigned(255)", "255", "18ff")
        runTest(UInt  (UInt8.max), "unsigned(255)", "255", "18ff")

        runTest(UInt16       .max,  "unsigned(65535)", "65535", "19ffff")
        runTest(UInt32(UInt16.max), "unsigned(65535)", "65535", "19ffff")
        runTest(UInt64(UInt16.max), "unsigned(65535)", "65535", "19ffff")
        runTest(UInt  (UInt16.max), "unsigned(65535)", "65535", "19ffff")

        runTest(UInt32(65536), "unsigned(65536)", "65536", "1a00010000")
        runTest(UInt64(65536), "unsigned(65536)", "65536", "1a00010000")
        runTest(UInt  (65536), "unsigned(65536)", "65536", "1a00010000")

        runTest(UInt32       .max,  "unsigned(4294967295)", "4294967295", "1affffffff")
        runTest(UInt64(UInt32.max), "unsigned(4294967295)", "4294967295", "1affffffff")
        runTest(UInt  (UInt32.max), "unsigned(4294967295)", "4294967295", "1affffffff")

        runTest(4294967296, "unsigned(4294967296)", "4294967296", "1b0000000100000000")

        runTest(UInt64.max, "unsigned(18446744073709551615)", "18446744073709551615", "1bffffffffffffffff")
        runTest(UInt  .max, "unsigned(18446744073709551615)", "18446744073709551615", "1bffffffffffffffff")
    }

    func testSigned() {
        runTest(Int8 (-1), "negative(-1)", "-1", "20")
        runTest(Int16(-1), "negative(-1)", "-1", "20")
        runTest(Int32(-1), "negative(-1)", "-1", "20")
        runTest(Int64(-1), "negative(-1)", "-1", "20")

        runTest(Int8 (-2), "negative(-2)", "-2", "21")
        runTest(Int16(-2), "negative(-2)", "-2", "21")
        runTest(Int32(-2), "negative(-2)", "-2", "21")
        runTest(Int64(-2), "negative(-2)", "-2", "21")

        runTest(Int8 (-127), "negative(-127)", "-127", "387e")
        runTest(Int16(-127), "negative(-127)", "-127", "387e")
        runTest(Int32(-127), "negative(-127)", "-127", "387e")
        runTest(Int64(-127), "negative(-127)", "-127", "387e")

        runTest(Int8 (Int8.min), "negative(-128)", "-128", "387f")
        runTest(Int16(Int8.min), "negative(-128)", "-128", "387f")
        runTest(Int32(Int8.min), "negative(-128)", "-128", "387f")
        runTest(Int64(Int8.min), "negative(-128)", "-128", "387f")

        runTest(Int8 (Int8.max), "unsigned(127)", "127", "187f")
        runTest(Int16(Int8.max), "unsigned(127)", "127", "187f")
        runTest(Int32(Int8.max), "unsigned(127)", "127", "187f")
        runTest(Int64(Int8.max), "unsigned(127)", "127", "187f")

        runTest(Int16(Int16.min), "negative(-32768)", "-32768", "397fff")
        runTest(Int32(Int16.min), "negative(-32768)", "-32768", "397fff")
        runTest(Int64(Int16.min), "negative(-32768)", "-32768", "397fff")

        runTest(Int16(Int16.max), "unsigned(32767)", "32767", "197fff")
        runTest(Int32(Int16.max), "unsigned(32767)", "32767", "197fff")
        runTest(Int64(Int16.max), "unsigned(32767)", "32767", "197fff")

        runTest(Int32(Int32.min), "negative(-2147483648)", "-2147483648", "3a7fffffff")
        runTest(Int64(Int32.min), "negative(-2147483648)", "-2147483648", "3a7fffffff")

        runTest(Int32(Int32.max), "unsigned(2147483647)", "2147483647", "1a7fffffff")
        runTest(Int64(Int32.max), "unsigned(2147483647)", "2147483647", "1a7fffffff")

        runTest(Int64.min, "negative(-9223372036854775808)", "-9223372036854775808", "3b7fffffffffffffff")

        runTest(Int64.max, "unsigned(9223372036854775807)", "9223372036854775807", "1b7fffffffffffffff")
    }

    func testBytes() {
        runTest(‡"112233", "bytes(112233)", "h'112233'", "43112233")
        runTest(
            ‡"c0a7da14e5847c526244f7e083d26fe33f86d2313ad2b77164233444423a50a7",
            "bytes(c0a7da14e5847c526244f7e083d26fe33f86d2313ad2b77164233444423a50a7)",
            "h'c0a7da14e5847c526244f7e083d26fe33f86d2313ad2b77164233444423a50a7'",
            "5820c0a7da14e5847c526244f7e083d26fe33f86d2313ad2b77164233444423a50a7")
    }
    
    func testArray() {
        runTest([1, 2, 3], "array([unsigned(1), unsigned(2), unsigned(3)])", "[1, 2, 3]", "83010203")
        runTest([1, -2, 3], "array([unsigned(1), negative(-2), unsigned(3)])", "[1, -2, 3]", "83012103")
    }
    
    func testMap() throws {
        var map = Map()
        map.insert(-1, 3)
        map.insert([-1], 7)
        map.insert("z", 4)
        map.insert(10, 1)
        map.insert(false, 8)
        map.insert(100, 2)
        map.insert("aa", 5)
        map.insert([100], 6)
        runTest(map,
             #"map({0x0a: (unsigned(10), unsigned(1)), 0x1864: (unsigned(100), unsigned(2)), 0x20: (negative(-1), unsigned(3)), 0x617a: (text("z"), unsigned(4)), 0x626161: (text("aa"), unsigned(5)), 0x811864: (array([unsigned(100)]), unsigned(6)), 0x8120: (array([negative(-1)]), unsigned(7)), 0xf4: (simple(false), unsigned(8))})"#,
             #"{10: 1, 100: 2, -1: 3, "z": 4, "aa": 5, [100]: 6, [-1]: 7, false: 8}"#,
             "a80a011864022003617a046261610581186406812007f408")
        XCTAssertNil(map[true] as Int?)
        XCTAssertEqual(map[-1], 3)
        XCTAssertEqual(map[[-1]], 7)
        XCTAssertEqual(map["z"], 4)
        XCTAssertNil(map["foo"] as Int?)
    }
    
    func testMapWithMapKeys() throws {
        var k1 = Map()
        k1.insert(1, 2)
        
        var k2 = Map()
        k2.insert(3, 4)
        
        var m = Map()
        m.insert(k1, 5)
        m.insert(k2, 6)
        runTest(m,
            #"map({0xa10102: (map({0x01: (unsigned(1), unsigned(2))}), unsigned(5)), 0xa10304: (map({0x03: (unsigned(3), unsigned(4))}), unsigned(6))})"#,
            #"{{1: 2}: 5, {3: 4}: 6}"#,
            "a2a1010205a1030406")
    }

    func testAndersMap() throws {
        let map: Map = [
            1: 45.7,
            2: "Hi there!"
        ]
        XCTAssertEqual(map.cborData, ‡"a201fb4046d9999999999a0269486920746865726521")
        XCTAssertEqual(map[1], 45.7)
    }

    func testMisorderedMap() {
        let mapWithOutOfOrderKeys = ‡"a8f4080a011864022003617a046261610581186406812007"
        XCTAssertThrowsError(try CBOR(mapWithOutOfOrderKeys)) {
            guard case CBORError.misorderedMapKey = $0 else {
                XCTFail()
                return
            }
        }
    }
    
    func testDuplicateKey() {
        let mapWithDuplicateKey = ‡"a90a011864022003617a046261610581186406812007f408f408"
        XCTAssertThrowsError(try CBOR(mapWithDuplicateKey)) {
            guard case CBORError.duplicateMapKey = $0 else {
                XCTFail()
                return
            }
        }
    }

    func testString() {
        runTest("Hello", #"text("Hello")"#, #""Hello""#, "6548656c6c6f")
    }
    
    func testNormalizedString() {
        let composedEAcute = "\u{00E9}" // é in NFC
        let decomposedEAcute = "\u{0065}\u{0301}" // e followed by ́ (combining acute accent) in NFD
        
        /// In Swift, string comparison is aware of compositional differences.
        XCTAssertEqual(composedEAcute, decomposedEAcute)
        
        /// Nonetheless, they serialize differently, which is not what we
        /// want for determinism.
        let utf81 = composedEAcute.data(using: .utf8)!
        let utf82 = decomposedEAcute.data(using: .utf8)!
        XCTAssertNotEqual(utf81, utf82)
        
        /// But serializing them as dCBOR yields the same data.
        let cbor1 = composedEAcute.cborData
        let cbor2 = decomposedEAcute.cborData
        XCTAssertEqual(cbor1, cbor2)
        
        /// dCBOR will reject the non-normalized form for deserialization.
        let decomposedStringCBORData = ‡"6365cc81"
        XCTAssertThrowsError(try CBOR(cborData: decomposedStringCBORData)) {
            guard case CBORError.nonCanonicalString = $0 else {
                XCTFail()
                return
            }
        }
    }
    
    func testTagged() {
        runTest(Tagged(1, "Hello"), #"tagged(1, text("Hello"))"#, #"1("Hello")"#, "c16548656c6c6f")
    }
    
    func testValue() {
        runTest(false, "simple(false)", "false", "f4")
        runTest(true, "simple(true)", "true", "f5")
//        runTest(Simple(100), "simple(100)", "simple(100)", "f864")
        
        XCTAssertEqual(CBOR.null.description, "null")
        XCTAssertEqual(CBOR.null.debugDescription, "simple(null)")
        XCTAssertEqual(CBOR.null.cborData, ‡"f6")
        XCTAssertEqual(try! CBOR(‡"f6"), CBOR.null)
    }
    
    func testUnusedData() {
        XCTAssertThrowsError(try CBOR(‡"0001")) {
            guard
                case CBORError.unusedData(let remaining) = $0,
                remaining == 1
            else {
                XCTFail()
                return
            }
        }
    }
    
    func testEnvelope() {
        let alice = CBOR.tagged(200, CBOR.tagged(24, "Alice"))
        let knows = CBOR.tagged(200, CBOR.tagged(24, "knows"))
        let bob = CBOR.tagged(200, CBOR.tagged(24, "Bob"))
        let knowsBob = CBOR.tagged(200, CBOR.tagged(221, [knows, bob]))
        let envelope = CBOR.tagged(200, [alice, knowsBob])
        XCTAssertEqual(envelope.description, #"200([200(24("Alice")), 200(221([200(24("knows")), 200(24("Bob"))]))])"#)
        let bytes = envelope.cborData
        XCTAssertEqual(bytes, ‡"d8c882d8c8d81865416c696365d8c8d8dd82d8c8d818656b6e6f7773d8c8d81863426f62")
        let decodedCBOR = try! CBOR(bytes)
        XCTAssertEqual(envelope, decodedCBOR)
    }
    
    func testFloat() throws {
        // Floating point numbers get serialized as their shortest accurate representation.
        runTest(1.5,                "simple(1.5)",          "1.5",          "f93e00")
        runTest(2345678.25,         "simple(2345678.25)",   "2345678.25",   "fa4a0f2b39")
        runTest(1.2,                "simple(1.2)",          "1.2",          "fb3ff3333333333333")

        // Floating point values that can be represented as integers get serialized as integers.
        runTest(Float(42.0),        "unsigned(42)",         "42",           "182a")
        runTest(2345678.0,          "unsigned(2345678)",    "2345678",      "1a0023cace")
        runTest(-2345678.0,         "negative(-2345678)",   "-2345678",     "3a0023cacd")
        
        // Negative zero gets serialized as integer zero.
        runTest(-0.0,               "unsigned(0)",          "0",            "00")
        
        // Smallest half-precision subnormal.
        runTest(5.960464477539063e-08, "simple(5.960464477539063e-08)", "5.960464477539063e-08", "f90001")
        
        // Smallest single subnormal.
        runTest(1.401298464324817e-45, "simple(1.401298464324817e-45)", "1.401298464324817e-45", "fa00000001")
        
        // Smallest double subnormal.
        runTest(5e-324, "simple(5e-324)", "5e-324", "fb0000000000000001")

        // Smallest double normal.
        runTest(2.2250738585072014e-308, "simple(2.2250738585072014e-308)", "2.2250738585072014e-308", "fb0010000000000000")

        // Smallest half-precision normal.
        runTest(6.103515625e-05, "simple(6.103515625e-05)", "6.103515625e-05", "f90400")

        // Largest possible half-precision.
        runTest(65504.0, "unsigned(65504)", "65504", "19ffe0")

        // Exponent 24 to test single exponent boundary.
        runTest(33554430.0, "unsigned(33554430)", "33554430", "1a01fffffe")

        // Most negative double that converts to int64.
        runTest(-9223372036854774784.0, "negative(-9223372036854774784)", "-9223372036854774784", "3b7ffffffffffffbff")

        // Int64 with too much precision to be a float.
        runTest(-9223372036854775807, "negative(-9223372036854775807)", "-9223372036854775807", "3b7ffffffffffffffe")
        
        // Most negative encoded as 65-bit neg
        // Can only be decoded as bignum
        runTestDecode(‡"3b8000000000000000", "negative(-9223372036854775809)", "-9223372036854775809")

        // Largest double that can convert to uint64, almost UINT64_MAX.
        runTest(18446744073709550000.0, "unsigned(18446744073709549568)", "18446744073709549568", "1bfffffffffffff800")

        // Just too large to convert to uint64, but converts to a single, just over UINT64_MAX.
        runTest(18446744073709552000.0, "simple(1.8446744073709552e+19)", "1.8446744073709552e+19", "fa5f800000")

        // Least negative float not representable as Int64
        runTest(-9223372036854777856.0, "negative(-9223372036854777856)", "-9223372036854777856", "3b80000000000007ff")

        // Next to most negative float encodable as 65-bit neg
        runTest(-18446744073709549568.0, "negative(-18446744073709549568)", "-18446744073709549568", "3bfffffffffffff7ff")

        // 65-bit neg encoded
        // not representable as double
        runTestDecode(‡"3bfffffffffffffffe", "negative(-18446744073709551615)", "-18446744073709551615")

        // Most negative encodable as a 65-bit neg
        runTest(-18446744073709551616.0, "negative(-18446744073709551616)", "-18446744073709551616", "3bffffffffffffffff")

        // Least negative whole integer that must be encoded as float in DCBOR (there are lots of non-whole-integer floats in the range of this table that must be DCBOR encoded as floats).
        runTest(-18446744073709555712.0, "simple(-1.8446744073709556e+19)", "-1.8446744073709556e+19", "fbc3f0000000000001")

        // Large negative that converts to negative int.
        runTest(-18446742974197924000.0, "negative(-18446742974197923840)", "-18446742974197923840", "3bfffffeffffffffff")

        // Largest possible single.
        runTest(3.4028234663852886e+38, "simple(3.4028234663852886e+38)", "3.4028234663852886e+38", "fa7f7fffff")

        // Slightly larger than largest possible single.
        runTest(3.402823466385289e+38, "simple(3.402823466385289e+38)", "3.402823466385289e+38", "fb47efffffe0000001")

        // Largest double.
        runTest(1.7976931348623157e+308, "simple(1.7976931348623157e+308)", "1.7976931348623157e+308", "fb7fefffffffffffff")
    }

    func testIntCoercedToFloat() throws {
        let n = 42
        let c = n.cbor
        let f = try Double(cbor: c)
        XCTAssertEqual(f, Double(n))
        let c2 = f.cbor
        XCTAssertEqual(c2, c)
        let i = try Int(cbor: c2)
        XCTAssertEqual(i, n)
    }
    
    func testFailFloatCoercedToInt() throws {
        // Floating point values cannot be coerced to integer types.
        let n = 42.5
        let c = n.cbor
        let f = try Double(cbor: c)
        XCTAssertEqual(f, n)
        XCTAssertThrowsError(try Int(cbor: c))
    }
        
    func testNonCanonicalFloat1() throws {
        // Non-canonical representation of 1.5 that could be represented at a smaller width.
        XCTAssertThrowsError(try CBOR(‡"fb3ff8000000000000"))
    }
    
    func testNonCanonicalFloat2() throws {
        // Non-canonical representation of a 12.0 value that could be represented as an integer.
        XCTAssertThrowsError(try CBOR(‡"f94a00"))
    }
    
    let canonicalNaNData = ‡"f97e00"
    let canonicalInfinityData = ‡"f97c00"
    let canonicalNegativeInfinityData = ‡"f9fc00"

    func testEncodeNaN() throws {
        let nonstandardDoubleNaN = Double(bitPattern: 0x7ff9100000000001)
        XCTAssert(nonstandardDoubleNaN.isNaN)
        XCTAssertEqual(nonstandardDoubleNaN.cborData, canonicalNaNData)
        
        let nonstandardFloatNaN = Float(bitPattern: 0xffc00001)
        XCTAssert(nonstandardFloatNaN.isNaN)
        XCTAssertEqual(nonstandardFloatNaN.cborData, canonicalNaNData)
        
        let nonstandardFloat16NaN = CBORFloat16(bitPattern: 0x7e01)
        XCTAssert(nonstandardFloat16NaN.isNaN)
        XCTAssertEqual(nonstandardFloat16NaN.cborData, canonicalNaNData)
    }
    
    func testDecodeNaN() throws {
        // Canonical NaN decodes
        XCTAssert(try Double(cbor: CBOR(canonicalNaNData)).isNaN)
        // Non-canonical NaNs of any size throw
        XCTAssertThrowsError(try CBOR(‡"f97e01"))
        XCTAssertThrowsError(try CBOR(‡"faffc00001"))
        XCTAssertThrowsError(try CBOR(‡"fb7ff9100000000001"))
    }
    
    func testEncodeInfinity() throws {
        XCTAssertEqual(Double.infinity.cborData, canonicalInfinityData)
        XCTAssertEqual(Float.infinity.cborData, canonicalInfinityData)
        XCTAssertEqual(CBORFloat16.infinity.cborData, canonicalInfinityData)
        XCTAssertEqual((-Double.infinity).cborData, canonicalNegativeInfinityData)
        XCTAssertEqual((-Float.infinity).cborData, canonicalNegativeInfinityData)
        XCTAssertEqual((-CBORFloat16.infinity).cborData, canonicalNegativeInfinityData)
    }
    
    func testDecodeInfinity() throws {
        // Canonical infinity decodes
        XCTAssert(try Double(cbor: CBOR(canonicalInfinityData)) == Double.infinity)
        XCTAssert(try Double(cbor: CBOR(canonicalNegativeInfinityData)) == -Double.infinity)

        // Non-canonical +infinities throw
        XCTAssertThrowsError(try CBOR(‡"fa7f800000"))
        XCTAssertThrowsError(try CBOR(‡"fb7ff0000000000000"))

        // Non-canonical -infinities throw
        XCTAssertThrowsError(try CBOR(‡"faff800000"))
        XCTAssertThrowsError(try CBOR(‡"fbfff0000000000000"))
    }
}
