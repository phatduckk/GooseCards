import Foundation

struct ImportedCardRow {
    let front: String
    let back: String
    let imageURLString: String?
}

enum CSVParser {
    /// Quote-aware CSV parser (handles embedded commas, "" escaped quotes, and
    /// \n / \r / \r\n line endings). Operates on Unicode scalars rather than
    /// Characters since Swift's Character type treats "\r\n" as a single
    /// grapheme cluster, which would never match a bare "\n" or "\r" literal.
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        let scalars = Array(text.unicodeScalars)
        var i = 0

        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < scalars.count, scalars[i + 1] == "\"" {
                        field.unicodeScalars.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else if c == "\r" {
                    // Normalize embedded CRLF/CR line breaks inside a quoted
                    // multi-line cell to a single "\n", so display code only
                    // ever has to reason about one newline convention.
                    field.unicodeScalars.append("\n")
                    if i + 1 < scalars.count, scalars[i + 1] == "\n" {
                        i += 1
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n", "\r":
                    row.append(field)
                    field = ""
                    rows.append(row)
                    row = []
                    if c == "\r", i + 1 < scalars.count, scalars[i + 1] == "\n" {
                        i += 1
                    }
                default:
                    field.unicodeScalars.append(c)
                }
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }

    /// Parses a "Front,Back,ImageURL" card CSV (header row required, ImageURL optional per row).
    static func parseCards(from csvText: String) -> [ImportedCardRow] {
        let rows = parse(csvText)
        guard rows.count > 1 else { return [] }
        return rows.dropFirst().compactMap { columns in
            guard columns.count >= 2 else { return nil }
            let front = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !front.isEmpty, !back.isEmpty else { return nil }
            let rawImageURL = columns.count >= 3 ? columns[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            return ImportedCardRow(front: front, back: back, imageURLString: rawImageURL.isEmpty ? nil : rawImageURL)
        }
    }
}
