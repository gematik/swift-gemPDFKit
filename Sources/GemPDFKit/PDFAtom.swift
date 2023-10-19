//
// Copyright (c) 2023 gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Parsing

public enum PDFAtom: Hashable, Equatable, CustomStringConvertible, Comparable {
    public static func <(lhs: PDFAtom, rhs: PDFAtom) -> Bool {
        switch (lhs, rhs) {
        case let (.name(lhsName), .name(rhsName)):
            return lhsName < rhsName
        default:
            return true
        }
    }

    case name(String)
    case double(Double)
    case int(Int)
    case string(String)
    case hexString(String)
    case reference(Int, Int)
    case dictionary([PDFAtom: PDFAtom])
    case array([PDFAtom])

    public var description: String {
        switch self {
        case let .name(name):
            return "/\(name)"
        case let .double(value):
            return "\(value)"
        case let .int(value):
            return "\(value)"
        case let .string(value):
            return "(\(value))"
        case let .hexString(value):
            return Data(value.utf8).map { String(format: "%02x", $0) }.joined()
        case let .reference(ref, sub):
            return "\(ref) \(sub) R"
        case let .dictionary(dictionary):
            return "<<\(dictionary.map { "\($0.description) \($1.description)" }.joined(separator: " "))>>"
        case let .array(values):
            return "[\(values.map(\.description).joined(separator: " "))]"
        }
    }
}

extension StringProtocol {
    func components(separatedByIncluding delims: CharacterSet) -> [String] {
        var components: [String] = []
        var component = ""

        for character in self {
            if String(character).rangeOfCharacter(from: delims) != nil {
                if !component.isEmpty {
                    components.append(component)
                }
                components.append(String(character))
                component = ""
            } else {
                component += [character]
            }
        }
        if !component.isEmpty {
            components.append(component)
        }

        return components
    }
}

extension String {
    func hexToString(encoding: Encoding = .utf16BigEndian) -> String {
        let characters = Array(self)
        let data = stride(from: 0, to: count, by: 2).compactMap { stride in
            let substring = characters[stride ..< min(stride + 2, characters.count)]
            return UInt8(String(substring), radix: 16)
        }
        return String(data: Data(data), encoding: encoding) ?? ""
    }

    func toHex(encoding: Encoding = .utf16BigEndian) -> String {
        let data = self.data(using: encoding) ?? Data()
        return data.map { String(format: "%02x", $0) }.joined()
    }
}

public struct HexStringConversion: Conversion {
    public func apply(_ input: Substring.UTF8View) throws -> String {
        String(input)?.hexToString() ?? ""
    }

    public func unapply(_ output: String) throws -> Substring.UTF8View {
        output.toHex().prefix { _ in true }.utf8
    }

    public init() {}

    public typealias Input = Substring.UTF8View

    public typealias Output = String
}

extension Conversion where Self == HexStringConversion {
    /// A conversion from `Substring.UTF8View` to `String`.
    ///
    /// Useful for transforming a ``ParserPrinter``'s UTF-8 output into a more general-purpose string.
    ///
    /// ```swift
    /// let line = Prefix { $0 != .init(ascii: "\n") }.map(.string)
    /// ```
    @inlinable public static var hexStringConversion: HexStringConversion {
        HexStringConversion()
    }
}

extension PDFAtom {
    struct NameParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            Whitespace()
            "/".utf8
            Prefix { (element: Substring.UTF8View.Element) in
                element != " ".utf8.first && element != "\n".utf8.first
            }.map(.string)
            Skip {
                Whitespace()
            }
        }
    }

    struct DoubleParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Double> {
            Whitespace()
            Double.parser()
            Skip {
                Whitespace()
            }
        }
    }

    struct IntParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Int> {
            Whitespace()
            Int.parser()
            Skip {
                Whitespace()
            }
        }
    }

    struct EscapedCharacterParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            OneOf {
                "\\".utf8.map { "\\" }
                "(".utf8.map { "(" }
                ")".utf8.map { ")" }
                "\n".utf8.map { "\n" }
                // These tokens appear within the PDF specification, but are not handled yet
                // "\r".utf8.map { "\r" }
                // "\t".utf8.map { "\t" }
                // "\b".utf8.map { "\b" }
                // "\f".utf8.map { "\f" }
            }
        }
    }

    static let escape: some ParserPrinter<Substring.UTF8View, String> = ParsePrint {
        "\\".utf8

        EscapedCharacterParserPrinter()
    }

    static let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")

    static let hexStringParser = HexStringParser()

    struct HexStringParser: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            Whitespace()

            "<".utf8

            Prefix { (element: Substring.UTF8View.Element) in
                element != ">".utf8.first &&
                    element != "<".utf8.first &&
                    hexCharacterSet.isSuperset(of: CharacterSet(charactersIn: String(element)))
            }.map(.hexStringConversion)

            ">".utf8

            Skip {
                Whitespace()
            }
        }
    }

    struct StringParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            Whitespace()
            "(".utf8
            Many(
                into: "",
                +=
            ) { string in
                string
                    .components(
                        separatedByIncluding: CharacterSet(
                            charactersIn: #"()\"#
                        )
                    )
                    .reversed()
                    .makeIterator()
            } element: {
                OneOf {
                    escape

                    Prefix(1...) { $0.isUnescapedPDFStringByte }.map(.string)
                }
            } terminator: {
                ")".utf8
            }

            Skip {
                Whitespace()
            }
        }
    }

    struct ReferenceParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, (Int, Int)> {
            Whitespace()
            Int.parser()
            " ".utf8
            Int.parser()
            " R".utf8
            Skip {
                Whitespace()
            }
        }
    }

    struct ArrayParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, [PDFAtom]> {
            OneOf {
                "[ ".utf8
                "[".utf8
            }
            Many {
                Lazy {
                    parser
                }
            } separator: {
                OneOf {
                    Whitespace()
                    " ".utf8
                }
            } terminator: {
                OneOf {
                    Whitespace()
                    " ".utf8
                }
                "]".utf8
            }
        }
    }

    struct DictionaryElementParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, (PDFAtom, PDFAtom)> {
            Not {
                ">>".utf8
            }
            NameParserPrinter().map(.case(PDFAtom.name))
            OneOf {
                Whitespace()
                " ".utf8
            }
            Lazy { parser }
        }
    }

    struct DictionaryParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, [PDFAtom: PDFAtom]> {
            Whitespace()
            "<<".utf8
            Many(
                into: [PDFAtom: PDFAtom]()
            ) { object, pair in
                let (name, value) = pair
                object[name] = value
            } decumulator: { object in
                (object.sorted { $0.key < $1.key } as [(PDFAtom, PDFAtom)]).reversed().makeIterator()
            } element: {
                DictionaryElementParserPrinter()
            } separator: {
                OneOf {
                    Whitespace()
                    " ".utf8
                }
            } terminator: {
                OneOf {
                    Whitespace()
                    " ".utf8
                }
                ">>".utf8
            }
        }
    }

    struct TerminatorParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Void> {
            OneOf {
                Whitespace()
                " ".utf8
            }
            ">>".utf8
        }
    }

    struct SeparatorParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Void> {
            OneOf {
                Whitespace()
                " ".utf8
            }
        }
    }

    struct ElementParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, (PDFAtom, PDFAtom)> {
            Not {
                ">>".utf8
            }
            NameParserPrinter().map(.case(PDFAtom.name))
            OneOf {
                Whitespace()
                " ".utf8
            }
            Lazy { parser }
        }
    }

    static let parser = PDFAtomParserPrinter()

    struct PDFAtomParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFAtom> {
            OneOf {
                NameParserPrinter().map(.case(PDFAtom.name))
                StringParserPrinter().map(.case(PDFAtom.string))
                HexStringParser().map(.case(PDFAtom.hexString))
                ReferenceParserPrinter().map(.case(PDFAtom.reference))
                IntParserPrinter().map(.case(PDFAtom.int))
                DoubleParserPrinter().map(.case(PDFAtom.double))

                DictionaryParserPrinter().map(.case(PDFAtom.dictionary))
                ArrayParserPrinter().map(.case(PDFAtom.array))
            }
        }
    }
}

extension UTF8.CodeUnit {
    var isUnescapedPDFStringByte: Bool {
        self != .init(ascii: ")") &&
            self != .init(ascii: "(") &&
            self != .init(ascii: "\\")
    }
}
