import Testing
import WolfBase
import DCBOR
import Foundation

let knownTags = TagsStore([Tag(1, "date")])

struct FormatTests {
    func literal(_ c: CBOR) -> CBOR { c }
    
    func run(_ cbor: [CBOR], description: String? = nil, debugDescription: String? = nil, diagnostic: String? = nil, diagnosticAnnotated: String? = nil, dump: String? = nil, dumpAnnotated: String? = nil) {
        #expect(cbor.dropFirst().allSatisfy { $0 == cbor.first })
        let c = cbor.first!
        if let description {
            #expect(c.description == description)
        }
        if let debugDescription {
            #expect(c.debugDescription == debugDescription)
        }
        if let diagnostic {
            #expect(c.diagnostic(annotate: false) == diagnostic)
        }
        if let diagnosticAnnotated {
            #expect(c.diagnostic(annotate: true, tags: knownTags) == diagnosticAnnotated)
        }
        if let dump {
            #expect(c.hex(annotate: false) == dump)
        }
        if let dumpAnnotated {
            #expect(c.hex(annotate: true, tags: knownTags) == dumpAnnotated)
        }
    }
    
    @Test func formatSimple() {
        run([CBOR(false), CBOR.false, false.cbor],
            description: "false",
            debugDescription:"simple(false)",
            diagnostic: "false",
            dump: "f4",
            dumpAnnotated: "f4 # false"
        )
        run([CBOR(true), CBOR.true, true.cbor],
            description: "true",
            debugDescription: "simple(true)",
            diagnostic: "true",
            dump: "f5",
            dumpAnnotated: "f5 # true"
        )
        run([CBOR(nil), CBOR.null, literal(nil)],
            description: "null",
            debugDescription: "simple(null)",
            diagnostic: "null",
            dump: "f6",
            dumpAnnotated: "f6 # null"
        )
    }
    
    @Test func formatUnsigned() {
        run([CBOR(0), 0.cbor, literal(0)],
            description: "0",
            debugDescription: "unsigned(0)",
            diagnostic: "0",
            dump: "00",
            dumpAnnotated: "00 # unsigned(0)"
        )

        run([CBOR(23), 23.cbor, literal(23)],
            description: "23",
            debugDescription: "unsigned(23)",
            diagnostic: "23",
            dump: "17",
            dumpAnnotated: "17 # unsigned(23)"
        )

        run([CBOR(65546), 65546.cbor, literal(65546)],
            description: "65546",
            debugDescription: "unsigned(65546)",
            diagnostic: "65546",
            dump: "1a0001000a",
            dumpAnnotated: "1a0001000a # unsigned(65546)"
        )

        run([CBOR(1000000000), 1000000000.cbor, literal(1000000000)],
            description: "1000000000",
            debugDescription: "unsigned(1000000000)",
            diagnostic: "1000000000",
            dump: "1a3b9aca00",
            dumpAnnotated: "1a3b9aca00 # unsigned(1000000000)"
        )
    }
    
    @Test func formatNegative() {
        run([CBOR(-1), (-1).cbor, literal(-1)],
            description: "-1",
            debugDescription: "negative(-1)",
            diagnostic: "-1",
            dump: "20",
            dumpAnnotated: "20 # negative(-1)"
        )

        run([CBOR(-1000), (-1000).cbor, literal(-1000)],
            description: "-1000",
            debugDescription: "negative(-1000)",
            diagnostic: "-1000",
            dump: "3903e7",
            dumpAnnotated: "3903e7 # negative(-1000)"
        )

        run([CBOR(-1000000), (-1000000).cbor, literal(-1000000)],
            description: "-1000000",
            debugDescription: "negative(-1000000)",
            diagnostic: "-1000000",
            dump: "3a000f423f",
            dumpAnnotated: "3a000f423f # negative(-1000000)"
        )
    }
    
    @Test func formatString() {
        run([CBOR("Test"), "Test".cbor, literal("Test")],
            description: #""Test""#,
            debugDescription: #"text("Test")"#,
            diagnostic: #""Test""#,
            dump: "6454657374",
            dumpAnnotated: """
            64          # text(4)
               54657374 # "Test"
            """
        )
    }
    
    @Test func formatSimpleArray() {
        run([CBOR([1, 2, 3]), [1, 2, 3].cbor, literal([1, 2, 3])],
            description: "[1, 2, 3]",
            debugDescription: "array([unsigned(1), unsigned(2), unsigned(3)])",
            diagnostic: "[1, 2, 3]",
            dump: "83010203",
            dumpAnnotated: """
            83    # array(3)
               01 # unsigned(1)
               02 # unsigned(2)
               03 # unsigned(3)
            """
        )
    }
    
    @Test func formatNestedArray() {
        let array: CBOR = [[1, 2, 3], ["A", "B", "C"]]
        run([array, literal([[1, 2, 3], ["A", "B", "C"]])],
            description: #"[[1, 2, 3], ["A", "B", "C"]]"#,
            debugDescription: #"array([array([unsigned(1), unsigned(2), unsigned(3)]), array([text("A"), text("B"), text("C")])])"#,
            diagnostic: """
            [
               [1, 2, 3],
               ["A", "B", "C"]
            ]
            """,
            dump: "828301020383614161426143",
            dumpAnnotated: """
            82          # array(2)
               83       # array(3)
                  01    # unsigned(1)
                  02    # unsigned(2)
                  03    # unsigned(3)
               83       # array(3)
                  61    # text(1)
                     41 # "A"
                  61    # text(1)
                     42 # "B"
                  61    # text(1)
                     43 # "C"
            """
        )
    }
    
    @Test func formatMap() throws {
        var map: Map = [1: "A"]
        map.insert(2, "B")
        run([map.cbor],
            description: #"{1: "A", 2: "B"}"#,
            debugDescription: #"map({0x01: (unsigned(1), text("A")), 0x02: (unsigned(2), text("B"))})"#,
            diagnostic: #"{1: "A", 2: "B"}"#,
            dump: "a2016141026142",
            dumpAnnotated: """
            a2       # map(2)
               01    # unsigned(1)
               61    # text(1)
                  41 # "A"
               02    # unsigned(2)
               61    # text(1)
                  42 # "B"
            """
        )
    }
    
    @Test func formatTagged() {
        run([CBOR.tagged(100, "Hello")],
            description: #"100("Hello")"#,
            debugDescription: #"tagged(100, text("Hello"))"#,
            diagnostic: #"100("Hello")"#,
            dump: "d8646548656c6c6f",
            dumpAnnotated: """
            d8 64            # tag(100)
               65            # text(5)
                  48656c6c6f # "Hello"
            """
        )
    }
    
    @Test func formatDate() {
        run([CBOR(Date(timeIntervalSince1970: -100))],
            description: "1(-100)",
            debugDescription: "tagged(1, negative(-100))",
            diagnostic: "1(-100)",
            diagnosticAnnotated: "1(1969-12-31T23:58:20Z)   / date /",
            dump: "c13863",
            dumpAnnotated: """
            c1      # tag(1) date
               3863 # negative(-100)
            """
        )
        
        run([CBOR(Date(timeIntervalSince1970: 1647887071))],
            description: "1(1647887071)",
            debugDescription: "tagged(1, unsigned(1647887071))",
            diagnostic: "1(1647887071)",
            diagnosticAnnotated: "1(2022-03-21T18:24:31Z)   / date /",
            dump: "c11a6238c2df",
            dumpAnnotated: """
            c1            # tag(1) date
               1a6238c2df # unsigned(1647887071)
            """
        )
        
        run([CBOR(Date(timeIntervalSince1970: 0))],
            description: "1(0)",
            debugDescription: "tagged(1, unsigned(0))",
            diagnostic: "1(0)",
            diagnosticAnnotated: "1(1970-01-01T00:00:00Z)   / date /",
            dump: "c100",
            dumpAnnotated: """
            c1    # tag(1) date
               00 # unsigned(0)
            """
        )
    }
    
    @Test func formatFractionalDate() {
        run([CBOR(Date(timeIntervalSince1970: 0.5))],
            description: "1(0.5)",
            debugDescription: "tagged(1, simple(0.5))",
            diagnostic: "1(0.5)",
            diagnosticAnnotated: "1(1970-01-01T00:00:00Z)   / date /",
            dump: "c1f93800",
            dumpAnnotated: """
            c1        # tag(1) date
               f93800 # 0.5
            """
        )
    }
    
    @Test func formatStructure() throws {
        let encodedCBOR = ‡"d83183015829536f6d65206d7973746572696573206172656e2774206d65616e7420746f20626520736f6c7665642e82d902c3820158402b9238e19eafbc154b49ec89edd4e0fb1368e97332c6913b4beb637d1875824f3e43bd7fb0c41fb574f08ce00247413d3ce2d9466e0ccfa4a89b92504982710ad902c3820158400f9c7af36804ffe5313c00115e5a31aa56814abaa77ff301da53d48613496e9c51a98b36d55f6fb5634fdb0123910cfa4904f1c60523df41013dc3749b377900"
        let diagnostic = """
        49(
           [
              1,
              h'536f6d65206d7973746572696573206172656e2774206d65616e7420746f20626520736f6c7665642e',
              [
                 707(
                    [
                       1,
                       h'2b9238e19eafbc154b49ec89edd4e0fb1368e97332c6913b4beb637d1875824f3e43bd7fb0c41fb574f08ce00247413d3ce2d9466e0ccfa4a89b92504982710a'
                    ]
                 ),
                 707(
                    [
                       1,
                       h'0f9c7af36804ffe5313c00115e5a31aa56814abaa77ff301da53d48613496e9c51a98b36d55f6fb5634fdb0123910cfa4904f1c60523df41013dc3749b377900'
                    ]
                 )
              ]
           ]
        )
        """

        run([try CBOR(encodedCBOR)],
            description: "49([1, h'536f6d65206d7973746572696573206172656e2774206d65616e7420746f20626520736f6c7665642e', [707([1, h'2b9238e19eafbc154b49ec89edd4e0fb1368e97332c6913b4beb637d1875824f3e43bd7fb0c41fb574f08ce00247413d3ce2d9466e0ccfa4a89b92504982710a']), 707([1, h'0f9c7af36804ffe5313c00115e5a31aa56814abaa77ff301da53d48613496e9c51a98b36d55f6fb5634fdb0123910cfa4904f1c60523df41013dc3749b377900'])]])",
            debugDescription: "tagged(49, array([unsigned(1), bytes(536f6d65206d7973746572696573206172656e2774206d65616e7420746f20626520736f6c7665642e), array([tagged(707, array([unsigned(1), bytes(2b9238e19eafbc154b49ec89edd4e0fb1368e97332c6913b4beb637d1875824f3e43bd7fb0c41fb574f08ce00247413d3ce2d9466e0ccfa4a89b92504982710a)])), tagged(707, array([unsigned(1), bytes(0f9c7af36804ffe5313c00115e5a31aa56814abaa77ff301da53d48613496e9c51a98b36d55f6fb5634fdb0123910cfa4904f1c60523df41013dc3749b377900)]))])]))",
            diagnostic: diagnostic,
            diagnosticAnnotated: diagnostic,
            dump: encodedCBOR.hex,
            dumpAnnotated: """
            d8 31                                    # tag(49)
               83                                    # array(3)
                  01                                 # unsigned(1)
                  5829                               # bytes(41)
                     536f6d65206d7973746572696573206172656e2774206d65616e7420746f20626520736f6c7665642e # "Some mysteries aren't meant to be solved."
                  82                                 # array(2)
                     d9 02c3                         # tag(707)
                        82                           # array(2)
                           01                        # unsigned(1)
                           5840                      # bytes(64)
                              2b9238e19eafbc154b49ec89edd4e0fb1368e97332c6913b4beb637d1875824f3e43bd7fb0c41fb574f08ce00247413d3ce2d9466e0ccfa4a89b92504982710a
                     d9 02c3                         # tag(707)
                        82                           # array(2)
                           01                        # unsigned(1)
                           5840                      # bytes(64)
                              0f9c7af36804ffe5313c00115e5a31aa56814abaa77ff301da53d48613496e9c51a98b36d55f6fb5634fdb0123910cfa4904f1c60523df41013dc3749b377900
            """
        )
    }
    
    @Test func formatStructure2() throws {
        let encodedCBOR = ‡"d9012ca4015059f2293a5bce7d4de59e71b4207ac5d202c11a6035970003754461726b20507572706c652041717561204c6f766504787b4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742c2073656420646f20656975736d6f642074656d706f7220696e6369646964756e74207574206c61626f726520657420646f6c6f7265206d61676e6120616c697175612e"
        let diagnosticAnnotated = """
        300(
           {
              1:
              h'59f2293a5bce7d4de59e71b4207ac5d2',
              2:
              1(2021-02-24T00:00:00Z),   / date /
              3:
              "Dark Purple Aqua Love",
              4:
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
           }
        )
        """
        let diagnostic = """
        300(
           {
              1:
              h'59f2293a5bce7d4de59e71b4207ac5d2',
              2:
              1(1614124800),
              3:
              "Dark Purple Aqua Love",
              4:
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
           }
        )
        """
        run([try CBOR(encodedCBOR)],
            description: #"300({1: h'59f2293a5bce7d4de59e71b4207ac5d2', 2: 1(1614124800), 3: "Dark Purple Aqua Love", 4: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."})"#,
            debugDescription: #"tagged(300, map({0x01: (unsigned(1), bytes(59f2293a5bce7d4de59e71b4207ac5d2)), 0x02: (unsigned(2), tagged(1, unsigned(1614124800))), 0x03: (unsigned(3), text("Dark Purple Aqua Love")), 0x04: (unsigned(4), text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."))}))"#,
            diagnostic: diagnostic,
            diagnosticAnnotated: diagnosticAnnotated,
            dump: encodedCBOR.hex,
            dumpAnnotated: """
            d9 012c                                  # tag(300)
               a4                                    # map(4)
                  01                                 # unsigned(1)
                  50                                 # bytes(16)
                     59f2293a5bce7d4de59e71b4207ac5d2
                  02                                 # unsigned(2)
                  c1                                 # tag(1) date
                     1a60359700                      # unsigned(1614124800)
                  03                                 # unsigned(3)
                  75                                 # text(21)
                     4461726b20507572706c652041717561204c6f7665 # "Dark Purple Aqua Love"
                  04                                 # unsigned(4)
                  78 7b                              # text(123)
                     4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742c2073656420646f20656975736d6f642074656d706f7220696e6369646964756e74207574206c61626f726520657420646f6c6f7265206d61676e6120616c697175612e # "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
            """
        )
    }
    
    /// Ensure that key order conforms to:
    /// https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1-2.3.2.1
    @Test func formatKeyOrder() throws {
        var map = Map()
        map[-1] = 3
        map[[-1]] = 7
        map["z"] = 4
        map[10] = 1
        map[false] = 8
        map[100] = 2
        map["aa"] = 5
        map[[100]] = 6
        let diagnostic = """
        {
           10:
           1,
           100:
           2,
           -1:
           3,
           "z":
           4,
           "aa":
           5,
           [100]:
           6,
           [-1]:
           7,
           false:
           8
        }
        """
        run([CBOR(map)],
            description: #"{10: 1, 100: 2, -1: 3, "z": 4, "aa": 5, [100]: 6, [-1]: 7, false: 8}"#,
            debugDescription: #"map({0x0a: (unsigned(10), unsigned(1)), 0x1864: (unsigned(100), unsigned(2)), 0x20: (negative(-1), unsigned(3)), 0x617a: (text("z"), unsigned(4)), 0x626161: (text("aa"), unsigned(5)), 0x811864: (array([unsigned(100)]), unsigned(6)), 0x8120: (array([negative(-1)]), unsigned(7)), 0xf4: (simple(false), unsigned(8))})"#,
            diagnostic: diagnostic,
            dump: "a80a011864022003617a046261610581186406812007f408",
            dumpAnnotated: """
            a8         # map(8)
               0a      # unsigned(10)
               01      # unsigned(1)
               1864    # unsigned(100)
               02      # unsigned(2)
               20      # negative(-1)
               03      # unsigned(3)
               61      # text(1)
                  7a   # "z"
               04      # unsigned(4)
               62      # text(2)
                  6161 # "aa"
               05      # unsigned(5)
               81      # array(1)
                  1864 # unsigned(100)
               06      # unsigned(6)
               81      # array(1)
                  20   # negative(-1)
               07      # unsigned(7)
               f4      # false
               08      # unsigned(8)
            """
        )
    }
}
