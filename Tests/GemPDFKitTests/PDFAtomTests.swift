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

@testable import GemPDFKit
import Nimble
import Parsing
import XCTest

final class PDFAtomTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParsingName() throws {
        let result = try PDFAtom.NameParserPrinter().parse("/Name ")
        expect(result).to(equal("Name"))
    }

    func testParsingNameBeforeLinebreak() throws {
        let result = try PDFAtom.NameParserPrinter().parse("/Name\n")
        expect(result).to(equal("Name"))
        expect(try PDFAtom.NameParserPrinter().parse("/Name")).to(equal("Name"))
        expect(try PDFAtom.NameParserPrinter().parse(" /Name ")).to(equal("Name"))
        expect(try PDFAtom.NameParserPrinter().parse("  /Name  ")).to(equal("Name"))
    }

    func testPrintingName() throws {
        expect(String(try PDFAtom.NameParserPrinter().print("Name"))).to(equal("/Name"))
        expect(String(try PDFAtom.parser.print(.name("Name")))).to(equal("/Name"))
    }

    func testParsingFloat() throws {
        expect(try PDFAtom.DoubleParserPrinter().parse("123.123")).to(equal(123.123))
        expect(try PDFAtom.DoubleParserPrinter().parse("123.123 ")).to(equal(123.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(" 123.123")).to(equal(123.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(" 123.123 ")).to(equal(123.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(".123")).to(equal(0.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(".123 ")).to(equal(0.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(" .123")).to(equal(0.123))
        expect(try PDFAtom.DoubleParserPrinter().parse(" .123 ")).to(equal(0.123))

        expect(try PDFAtom.DoubleParserPrinter().parse("123")).to(equal(123.0))
    }

    func testParsingInt() throws {
        expect(try PDFAtom.IntParserPrinter().parse("123")).to(equal(123))
        expect(try PDFAtom.IntParserPrinter().parse("123 ")).to(equal(123))
        expect(try PDFAtom.IntParserPrinter().parse(" 123")).to(equal(123))
        expect(try PDFAtom.IntParserPrinter().parse("  123  ")).to(equal(123))

        expect(try PDFAtom.IntParserPrinter().parse("123.1")).to(throwError())
        expect(try PDFAtom.IntParserPrinter().parse(".123")).to(throwError())
    }

    func testPrintingInt() throws {
        expect(String(try PDFAtom.IntParserPrinter().print(123))).to(equal("123"))
        expect(String(try PDFAtom.parser.print(.int(123)))).to(equal("123"))
    }

    func testParsingReference() throws {
        expect(try PDFAtom.ReferenceParserPrinter().parse(" 1 2 R ")).to(equal((1, 2)))
        expect(try PDFAtom.ReferenceParserPrinter().parse("1 2 R ")).to(equal((1, 2)))
        expect(try PDFAtom.ReferenceParserPrinter().parse("1 2 R\n")).to(equal((1, 2)))
        expect(try PDFAtom.parser.parse(" 1 2 R ")).to(equal(.reference(1, 2)))
        expect(try PDFAtom.parser.parse("1 2 R ")).to(equal(.reference(1, 2)))
        expect(try PDFAtom.parser.parse("1 2 R\n")).to(equal(.reference(1, 2)))
    }

    func testPrintingReference() throws {
        expect(String(try PDFAtom.ReferenceParserPrinter().print((1, 2)))).to(equal("1 2 R"))
        expect(String(try PDFAtom.parser.print(.reference(1, 2)))).to(equal("1 2 R"))
    }

    func testParsingString() throws {
        expect(try PDFAtom.StringParserPrinter().parse("(E-Rezept-App) ")).to(equal("E-Rezept-App"))
        expect(try PDFAtom.StringParserPrinter().parse("(E-Rezept-App)\n")).to(equal("E-Rezept-App"))
        expect(try PDFAtom.StringParserPrinter().parse("(E-Rezept-\\\\App)\n")).to(equal(#"E-Rezept-\App"#))
        expect(try PDFAtom.parser.parse(#"(E-Rezept-\\App) "#)).to(equal(.string(#"E-Rezept-\App"#)))
        expect(try PDFAtom.parser.parse("(E-Rezept-App) ")).to(equal(.string("E-Rezept-App")))
        expect(try PDFAtom.parser.parse("(E-Rezept-App)\n")).to(equal(.string("E-Rezept-App")))
    }

    func testPrintingString() throws {
        expect(String(try PDFAtom.StringParserPrinter().print(#"iOS Version 16.2 (Build 20C52) Quartz PDFContext"#)))
            .to(equal(#"(iOS Version 16.2 \(Build 20C52\) Quartz PDFContext)"#))

        expect(String(try PDFAtom.StringParserPrinter().print(#"E"#))).to(equal(#"(E)"#))
        expect(String(try PDFAtom.StringParserPrinter().print(#"E("#))).to(equal(#"(E\()"#))
        expect(String(try PDFAtom.StringParserPrinter().print(#"ER"#))).to(equal(#"(ER)"#))
        expect(String(try PDFAtom.StringParserPrinter().print(#"ER\"#))).to(equal(#"(ER\\)"#))
        expect(String(try PDFAtom.StringParserPrinter().print("E-Rezept-App"))).to(equal("(E-Rezept-App)"))
        expect(String(try PDFAtom.parser.print(.string("E-Rezept-App")))).to(equal("(E-Rezept-App)"))
    }

    func testParsingHexString() throws {
        expect("00740065007300740064006100740061".hexToString()).to(equal("testdata"))
        expect("testdata".toHex()).to(equal("00740065007300740064006100740061"))

        expect(try PDFAtom.HexStringParser().parse("<00740065007300740064006100740061> ")).to(equal("testdata"))
        expect(try PDFAtom.HexStringParser().parse("<00740065007300740064006100740061>\n")).to(equal("testdata"))
        expect(try PDFAtom.parser.parse("<00740065007300740064006100740061> ")).to(equal(.hexString("testdata")))
        expect(try PDFAtom.parser.parse("<00740065007300740064006100740061>\n")).to(equal(.hexString("testdata")))

        expect(try PDFAtom.parser.parse("<00740065007300740064006100740061d83eddf8>\n"))
            .to(equal(.hexString("testdata🧸")))
    }

    func testPrintingHexString() throws {
        expect(String(try PDFAtom.HexStringParser().print("testdata"))).to(equal("<00740065007300740064006100740061>"))
        expect(String(try PDFAtom.parser.print(.hexString("testdata")))).to(equal("<00740065007300740064006100740061>"))
        expect(String(try PDFAtom.parser.print(.hexString("testdata🧸"))))
            .to(equal("<00740065007300740064006100740061d83eddf8>"))
    }

    func testParsingDictionary() throws {
        let expectedSubDictionary: [PDFAtom: PDFAtom] = [
            .name("Length"): .int(114),
        ]
        let expected: [PDFAtom: PDFAtom] = [
            .name("Filter"): .dictionary(expectedSubDictionary),
        ]

        expect(try PDFAtom.DictionaryParserPrinter().parse("<< /Filter << /Length 114 >> >>")).to(equal(expected))
        expect(try PDFAtom.DictionaryParserPrinter().parse("<< /Length 114 >>")).to(equal(expectedSubDictionary))
    }

    func testPrintingNextedDictionary() throws {
        let expected: [PDFAtom: PDFAtom] = [
            .name("Filter"): .dictionary([
                .name("Length"): .int(114),
            ]),
        ]

        expect(String(try PDFAtom.parser.print(.dictionary(expected))))
            .to(equal("<</Filter <</Length 114 >> >>"))
    }

    func testParsingNextedDictionary() throws {
        let expected: [PDFAtom: PDFAtom] = [
            .name("Filter"): .name("FlateDecode"),
            .name("Length"): .int(114),
        ]

        expect(try PDFAtom.DictionaryParserPrinter().parse("<</Filter /FlateDecode /Length 114 >>")).to(equal(expected))
    }

    func testPrintingDictionaryOrder() throws {
        let input: PDFAtom = .dictionary([
            .name("B"): .name("B"),
            .name("A"): .name("A"),
            .name("G"): .name("G"),
            .name("D"): .name("D"),
            .name("E"): .name("E"),
            .name("C"): .name("C"),
            .name("F"): .name("F"),
        ])

        let expected = "<</A /A /B /B /C /C /D /D /E /E /F /F /G /G >>"

        expect(String(try PDFAtom.parser.print(input))).to(equal(expected))
    }

    func testPrintingDictionary() throws {
        let input: PDFAtom = .dictionary([
            .name("Producer"): .string("iOS Version 16.2 (Build 20C52) Quartz PDFContext"),
            .name("Author"): .string("E-Rezept-App"),
            .name("Creator"): .string("E-Rezept-App"),
            .name("CreationDate"): .string("D:20230315190730Z00'00'"),
            .name("ModDate"): .string("D:20230315190730Z00'00'"),
        ])

        let expected =
            #"<</Author (E-Rezept-App) /CreationDate (D:20230315190730Z00'00') /Creator (E-Rezept-App) /ModDate (D:20230315190730Z00'00') /Producer (iOS Version 16.2 \(Build 20C52\) Quartz PDFContext) >>"# // swiftlint:disable:this line_length

        expect(String(try PDFAtom.parser.print(input))).to(equal(expected))
    }

    func testParsingArray() throws {
        let result = try PDFAtom.ArrayParserPrinter().parse("[ /ICCBased 8 0 R ]")
        expect(result).to(equal([.name("ICCBased"), .reference(8, 0)]))
    }

    func testParsingDictionaryWithLineBreak() throws {
        let result = try PDFAtom.parser
            .parse(
                "<< /Size 16 /Root 9 0 R /Info 15 0 R /ID [ (86c5ff144a60ad5754d444d36fb278ff)\n(86c5ff144a60ad5754d444d36fb278ff) ] >>" // swiftlint:disable:this line_length
            )

        let expected = PDFAtom.dictionary([
            .name("Size"): .int(16),
            .name("Root"): .reference(9, 0),
            .name("Info"): .reference(15, 0),
            .name("ID"): .array([
                .string("86c5ff144a60ad5754d444d36fb278ff"),
                .string("86c5ff144a60ad5754d444d36fb278ff"),
            ]),
        ])

        expect(result).to(equal(expected))
    }
}
