//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import Foundation
@testable import GemPDFKit
import Nimble
import Parsing
import XCTest

final class PDFDocumentPartTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParsingDocument1() throws {
        let input = #"""
        1 0 obj
        << /Object /1 >>
        endobj
        xref
        0 16
        0000000000 65535 f
        trailer
        << /Size 16 /Root 9 0 R /Info 15 0 R /ID [ <86c5ff144a60ad5754d444d36fb278ff>
        <86c5ff144a60ad5754d444d36fb278ff> ] >>
        startxref
        7298
        %%EOF

        """#

        let result = try PDFDocumentPart.PDFDocumentPartParserPrinter().parse(input)

        expect({ result.objects.count }).to(equal(1))
    }

    func testParsingDocument2() throws {
        let input = #"""
        9 0 obj
        <</Type /Catalog /Pages 2 0 R /Names <</EmbeddedFiles 18 0 R >> >>
        endobj
        16 0 obj
        <</Length 8 /Params <</Size 8 >> >> stream
        testdata
        endstream

        endobj
        17 0 obj
        <</Type /Filespec /UF <feff00740065007300740064006100740061> /EF <</F 16 0 R >> >>
        endobj
        18 0 obj
        <</Names [<feff00740065007300740064006100740061> 17 0 R ] >>
        endobj
        xref
        0 1
        0000000001 65535 f
        9 1
        0000007775 00000 n
        16 3
        0000007861 00000 n
        0000007946 00000 n
        0000008049 00000 n
        trailer
        <</Size 19 /ID [ (1231231123132132) (123312312312123123123) ] /Root 9 0 R /Prev 7298 /Info 15 0 R >>
        startxref
        8130
        %%EOF

        """#

        let result = try PDFDocumentPart.PDFDocumentPartParserPrinter().parse(input)

        expect(result.objects.count).to(equal(4))
    }

    func testParsingDocumentPart1() throws {
        let data = try testResource(name: "document_part", extension: "data")
        let inputString = String(data: data, encoding: .isoLatin1)!

        let result = try PDFDocumentPart.PDFDocumentPartParserPrinter().parse(inputString)

        expect(result.objects.count).to(equal(15))
    }

    func testXRefSectionObjectReferenceParsing() throws {
        let expected = PDFXRef.Section.ObjectReference(startOffset: 1, generation: 65535, usage: .free)
        let result = try PDFXRef.SectionObjectReferenceParserPrinter().parse("0000000001 65535 f\n")
        expect(result).to(equal(expected))
    }

    func testXRefSectionParsing() throws {
        let expected = PDFXRef.Section(identifier: 0, count: 1, elements: [
            .init(startOffset: 1, generation: 65535, usage: .free),
        ])

        let result = try PDFXRef.SectionParserPrinter().parse("0 1\n0000000001 65535 f\n")

        expect(result).to(equal(expected))
    }

    func testXRefSectionParsing2() throws {
        let expected = PDFXRef.Section(identifier: 9, count: 1, elements: [
            .init(startOffset: 7775, generation: 0, usage: .inUse),
        ])

        let result = try PDFXRef.SectionParserPrinter().parse("9 1\n0000007775 00000 n\n")

        expect(result).to(equal(expected))
    }

    func testXRefSectionParsing3() throws {
        let expected = PDFXRef.Section(identifier: 16, count: 3, elements: [
            .init(startOffset: 7861, generation: 0, usage: .inUse),
            .init(startOffset: 7946, generation: 0, usage: .inUse),
            .init(startOffset: 8049, generation: 0, usage: .inUse),
        ])

        let input = """
        16 3
        0000007861 00000 n
        0000007946 00000 n
        0000008049 00000 n

        """

        let result = try PDFXRef.SectionParserPrinter().parse(input)

        expect(result).to(equal(expected))
    }

    func testXRefParsing() throws {
        expect(try PDFXRef.SectionParserPrinter().parse("0 1\n0000000001 65535 f\n"))
            .to(equal(.init(identifier: 0,
                            count: 1,
                            elements: [
                                .init(startOffset: 1, generation: 65535, usage: .free),
                            ])))

        let input = """
        xref
        0 1
        0000000001 65535 f
        9 1
        0000007775 00000 n
        16 3
        0000007861 00000 n
        0000007946 00000 n
        0000008049 00000 n

        """

        let result = try PDFXRef.XRefParserPrinter().parse(input)
        let expected = PDFXRef(sections: [
            .init(identifier: 0, count: 1, elements: [
                .init(startOffset: 1, generation: 65535, usage: .free),
            ]),
            .init(identifier: 9, count: 1, elements: [
                .init(startOffset: 7775, generation: 0, usage: .inUse),
            ]),
            .init(identifier: 16, count: 3, elements: [
                .init(startOffset: 7861, generation: 0, usage: .inUse),
                .init(startOffset: 7946, generation: 0, usage: .inUse),
                .init(startOffset: 8049, generation: 0, usage: .inUse),
            ]),
        ])

        expect(result).to(equal(expected))
    }
}

extension XCTestCase {
    func testResourceURL(name: String, extension ext: String) -> URL {
        let bundle = Bundle.module
        let testDataPath = bundle.path(forResource: name, ofType: ext, inDirectory: "TestData")
        return URL(fileURLWithPath: testDataPath!)
        // beginning with iOS16 one can use:
        // return URL.init(filePath: testDataPath!)
    }

    func outputResourceURL(name: String, extension ext: String) -> URL {
        let bundle = Bundle(for: Self.self)
        var url = bundle.bundleURL

        url.appendPathComponent("\(name).\(ext)")
        return url
    }

    func testResource(name: String, extension ext: String) throws -> Data {
        let url = testResourceURL(name: name, extension: ext)
        return try Data(contentsOf: url)
    }
}
