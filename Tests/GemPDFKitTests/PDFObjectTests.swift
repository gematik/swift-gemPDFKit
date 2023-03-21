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

final class PDFObjectTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParsingObject1() throws {
        let sut1 = """
        10 0 obj
        << /FontFile
        11 0 R >>
        endobj

        """

        let sut2 = """
        10 0 obj
        << /FontFile 11 0 R >>
        endobj

        """

        let expected = PDFObject(
            identifier: 10,
            counter: 0,
            atom: .dictionary([.name("FontFile"): .reference(11, 0)]),
            stream: nil
        )

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut1)).to(equal(expected))
        expect(try PDFObject.PDFObjectParserPrinter().parse(sut2)).to(equal(expected))
    }

    func testParsingObject2() throws {
        let sut1 = """
        3 0 obj
        << /Filter /FlateDecode /Length 114 >>
        stream
        dfsfdfskjlsdfjkldsfjklsdfjklsdf jkls
        endstream

        endobj

        """

        let expected = PDFObject(
            identifier: 3,
            counter: 0,
            atom: .dictionary([
                .name("Filter"): .name("FlateDecode"),
                .name("Length"): .int(114),
            ]),
            stream: .init(stream: "dfsfdfskjlsdfjkldsfjklsdfjklsdf jkls")
        )

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut1)).to(equal(expected))
    }

    func testParsingObject3() throws {
        let sut1 = #"""
        15 0 obj
        << /Producer (iOS Version 16.2 \(Build 20C52\) Quartz PDFContext) /Author
        (E-Rezept-App) /Creator (E-Rezept-App) /CreationDate (D:20230315190730Z00'00')
        /ModDate (D:20230315190730Z00'00') >>
        endobj

        """#

        let expected = PDFObject(
            identifier: 15,
            counter: 0,
            atom: .dictionary([
                .name("Producer"): .string("iOS Version 16.2 (Build 20C52) Quartz PDFContext"),
                .name("Author"): .string("E-Rezept-App"),
                .name("Creator"): .string("E-Rezept-App"),
                .name("CreationDate"): .string("D:20230315190730Z00'00'"),
                .name("ModDate"): .string("D:20230315190730Z00'00'"),
            ]),
            stream: nil
        )

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut1)).to(equal(expected))
    }

    func testParsingObject4() throws {
        let sut1 = """
        15 0 obj
        [ /ICCBased 8 0 R ]
        endobj

        """

        let expected = PDFObject(
            identifier: 15,
            counter: 0,
            atom: .array([
                .name("ICCBased"),
                .reference(8, 0),
            ]),
            stream: nil
        )

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut1)).to(equal(expected))
    }

    func testParsingObject5() throws {
        let sut1 = """
        16 0 obj
        <</Length 8 /Params <</Size 8 >> >> stream
        testdata
        endstream

        endobj

        """

        let sut2 = """
        17 0 obj
        <</Type /Filespec /UF <feff00740065007300740064006100740061> /EF <</F 16 0 R >> >>
        endobj

        """

        let expected = PDFObject(
            identifier: 16,
            counter: 0,
            atom: .dictionary([
                .name("Length"): .int(8),
                .name("Params"): .dictionary([
                    .name("Size"): .int(8),
                ]),
            ]),
            stream: .init(stream: "testdata")
        )

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut1)).to(equal(expected))

        expect(try PDFObject.PDFObjectParserPrinter().parse(sut2)).toNot(throwError())
    }

    func testPrintingObject() throws {
        let expected = "15 0 obj\n<</A /B >>\nendobj\n"

        let input = PDFObject(
            identifier: 15,
            counter: 0,
            atom: .dictionary([
                .name("A"): .name("B"),
            ]),
            stream: nil
        )

        expect(String(try PDFObject.PDFObjectParserPrinter().print(input))).to(equal(expected))
    }

    func testPrintingObject3() throws {
        let expected =
            "15 0 obj\n<</Author (E-Rezept-App) /CreationDate (D:20230315190730Z00'00') /Creator (E-Rezept-App) /ModDate (D:20230315190730Z00'00') /Producer (iOS Version 16.2 \\(Build 20C52\\) Quartz PDFContext) >>\nendobj\n" // swiftlint:disable:this line_length

        let input = PDFObject(
            identifier: 15,
            counter: 0,
            atom: .dictionary([
                .name("Producer"): .string("iOS Version 16.2 (Build 20C52) Quartz PDFContext"),
                .name("Author"): .string("E-Rezept-App"),
                .name("Creator"): .string("E-Rezept-App"),
                .name("CreationDate"): .string("D:20230315190730Z00'00'"),
                .name("ModDate"): .string("D:20230315190730Z00'00'"),
            ]),
            stream: nil
        )

        expect(String(try PDFObject.PDFObjectParserPrinter().print(input))).to(equal(expected))
    }
}
