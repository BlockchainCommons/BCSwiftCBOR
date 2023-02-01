import Foundation
import WolfBase

public extension CBOR {
    /// Returns the CBOR value as a hex dump.
    ///
    /// - Parameters:
    ///   - annotate: If `true`, add additional notes and context, otherwise just return a
    ///   straight hexadecimal encoding.
    ///   - knownTags: If `annotate` is `true`, uses the name of these tags rather than their number.
    func dump(annotate: Bool = false, knownTags: KnownTags? = nil) -> String {
        guard annotate == true else {
            return encodeCBOR().hex
        }
        let items = dumpItems(level: 0, knownTags: knownTags)
        let noteColumn = items.reduce(into: 0) { largest, item in
            largest = max(largest, item.formatFirstColumn().count)
        }
        let lines = items.map { $0.format(noteColumn: noteColumn) }
        return lines.joined(separator: "\n")
    }
}

struct DumpItem {
    let level: Int
    let data: [Data]
    let note: String?
    
    init(level: Int, data: [Data], note: String? = nil) {
        self.level = level
        self.data = data
        self.note = note
    }

    init(level: Int, data: Data, note: String? = nil) {
        self.init(level: level, data: [data], note: note)
    }
    
    func format(noteColumn: Int) -> String {
        let column1 = formatFirstColumn()
        let column2: String
        let padding: String
        if let note = note {
            let paddingCount = max(1, min(40, noteColumn) - column1.count + 1)
            padding = String(repeating: " ", count: paddingCount)
            column2 = "# " + note
        } else {
            padding = ""
            column2 = ""
        }
        return column1 + padding + column2
    }
    
    func formatFirstColumn() -> String {
        let indent = String(repeating: " ", count: level * 3)
        let hex = data.map { $0.hex }.filter { !$0.isEmpty }.joined(separator: " ")
        return indent + hex
    }
}

extension CBOR {
    func dumpItems(level: Int, knownTags: KnownTags?) -> [DumpItem] {
        switch self {
        case .unsigned(let n):
            return [DumpItem(level: level, data: self.encodeCBOR(), note: "unsigned(\(n))")]
        case .negative(let n):
            return [DumpItem(level: level, data: self.encodeCBOR(), note: "negative(\(n))")]
        case .bytes(let d):
            let note = d.utf8?.sanitized?.flanked("\"")
            var items = [
                DumpItem(level: level, data: d.count.encodeVarInt(.bytes), note: "bytes(\(d.count))")
            ]
            if !d.isEmpty {
                items.append(DumpItem(level: level + 1, data: d, note: note))
            }
            return items
        case .text(let s):
            let stringHeader = s.count.encodeVarInt(.text)
            return [
                DumpItem(level: level, data: [Data(of: stringHeader.first!), stringHeader.dropFirst()], note: "text(\(s.utf8Data.count))"),
                DumpItem(level: level + 1, data: s.utf8Data, note: s.flanked("\""))
            ]
        case .value(let v):
            let data = v.encodeCBOR()
            let note = v.description
            return [
                DumpItem(level: level, data: data, note: note)
            ]
        case .tagged(let tag, let item):
            let tagHeader = tag.value.encodeVarInt(.tagged)
            var noteComponents: [String] = [ "tag(\(tag))" ]
            if let name = knownTags?.assignedName(for: tag) {
                noteComponents.append("  ; \(name)")
            }
            let tagNote = noteComponents.joined(separator: " ")
            return [
                [
                    DumpItem(level: level, data: [Data(of: tagHeader.first!), tagHeader.dropFirst()], note: tagNote)
                ],
                item.dumpItems(level: level + 1, knownTags: knownTags)
            ].flatMap { $0 }
        case .array(let array):
            let arrayHeader = array.count.encodeVarInt(.array)
            let arrayHeaderData = [Data(of: arrayHeader.first!), arrayHeader.dropFirst()]
            return [
                [
                    DumpItem(level: level, data: arrayHeaderData, note: String(array.count).flanked("array(", ")"))
                ],
                array.flatMap { $0.dumpItems(level: level + 1, knownTags: knownTags) }
            ].flatMap { $0 }
        case .map(let m):
            let mapHeader = m.count.encodeVarInt(.map)
            let mapHeaderData = [Data(of: mapHeader.first!), mapHeader.dropFirst()]
            let entries = m.entries
            return [
                [
                    DumpItem(level: level, data: mapHeaderData, note: String(m.count).flanked("map(", ")"))
                ],
                entries.flatMap {
                    [
                        $0.key.dumpItems(level: level + 1, knownTags: knownTags),
                        $0.value.dumpItems(level: level + 1, knownTags: knownTags)
                    ].flatMap { $0 }
                }
            ].flatMap { $0 }
        }
    }
}

extension Character {
    var isPrintable: Bool {
        !isASCII || (32...126).contains(asciiValue!)
    }
}

extension String {
    var sanitized: String? {
        var hasPrintable = false
        let s = self.map { c -> Character in
            if c.isPrintable {
                hasPrintable = true
                return c
            } else {
                return "."
            }
        }
        return !hasPrintable ? nil : String(s)
    }
}
