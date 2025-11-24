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

@testable import GemPDFKit
import Nimble
import Parsing
import XCTest

final class PDFDocumentTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParsingDocument1() throws {
        let input = #"""
        %PDF-1.3
        %Äåòåë§ó ÐÄÆ
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

        let result = try PDFDocument.PDFDocumentParserPrinter().parse(input)

        expect(result.parts.count).to(equal(1))
        expect(result.parts.first?.objects.count).to(equal(1))
    }

    func testParsingDocument2() throws {
        let input = #"""
        %PDF-1.3
        %Äåòåë§ó ÐÄÆ
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

        let result = try PDFDocument.PDFDocumentParserPrinter().parse(input)

        expect(result.parts.count).to(equal(2))
        expect(result.parts.first?.objects.count).to(equal(1))
    }

    func testParsingTestDocument1() throws {
        let data = try testResource(name: "simple_pdf", extension: "pdf")
        let inputString = String(data: data, encoding: .isoLatin1)!.utf8

        let result = try PDFDocument.PDFDocumentParserPrinter().parse(inputString)

        print(inputString)

        expect(result.parts.count).to(equal(1))
        expect(result.parts.first?.objects.count).to(equal(15))
    }

    func testParsingTestDocument2() throws {
        let data = try testResource(name: "simple_pdf_out", extension: "pdf")
        let inputString = String(data: data, encoding: .isoLatin1)!.utf8

        let result = try PDFDocument.PDFDocumentParserPrinter().parse(inputString)

        print(inputString)

        expect(result.parts.count).to(equal(2))
        expect(result.parts.first?.objects.count).to(equal(15))
        expect(result.parts.last?.objects.count).to(equal(4))
    }

    func testParsingTestDocument3() throws {
        let input = #"""
        %PDF-1.3
        %Äåòåë§ó ÐÄÆ
        1 0 obj
        << /Type /Page /Parent 2 0 R /Resources 4 0 R /Contents 3 0 R >>
        endobj
        4 0 obj
        << /ProcSet [ /PDF /Text ] /ColorSpace << /Cs1 5 0 R >> /Font << /TT1 6 0 R
        /TT2 7 0 R >> >>
        endobj
        5 0 obj
        [ /ICCBased 8 0 R ]
        endobj
        2 0 obj
        << /Type /Pages /MediaBox [0 0 595.2744 841.8881] /Count 1 /Kids [ 1 0 R ]
        >>
        endobj
        9 0 obj
        << /Type /Catalog /Pages 2 0 R >>
        endobj
        6 0 obj
        << /Type /Font /Subtype /TrueType /BaseFont /AAAAAB+Helvetica-Bold /FontDescriptor
        10 0 R /Encoding /MacRomanEncoding /FirstChar 32 /LastChar 159 /Widths [ 278
        0 0 0 0 0 0 0 0 0 0 0 278 333 278 0 0 0 0 556 556 556 0 0 0 0 333 0 0 0 0
        0 0 722 722 0 722 667 611 778 0 278 0 722 0 833 0 0 667 0 722 667 0 722 0
        0 0 0 611 0 0 0 0 0 0 556 611 556 0 556 333 611 611 278 0 0 278 889 611 611
        611 0 389 556 333 611 556 778 0 0 500 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 556 0
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 611 0 0 0 0 611 ] >>
        endobj
        10 0 obj
        << /Type /FontDescriptor /FontName /AAAAAB+Helvetica-Bold /Flags 32 /FontBBox
        [-1018 -481 1372 962] /ItalicAngle 0 /Ascent 770 /Descent -230 /CapHeight
        720 /StemV 0 /XHeight 532 /AvgWidth 627 /MaxWidth 1500 /FontFile2 11 0 R >>
        endobj
        7 0 obj
        << /Type /Font /Subtype /TrueType /BaseFont /AAAAAC+Helvetica /FontDescriptor
        12 0 R /Encoding /MacRomanEncoding /FirstChar 32 /LastChar 167 /Widths [ 278
        0 0 0 0 0 0 0 0 0 0 0 278 0 278 0 556 556 556 556 556 556 556 556 556 556
        278 0 0 0 0 0 0 667 667 0 722 667 611 778 722 278 0 667 556 833 722 778 667
        0 722 667 611 722 0 944 667 0 0 0 0 0 0 556 0 556 556 500 556 556 278 556
        556 222 0 0 222 833 556 556 0 0 333 500 278 556 0 0 0 500 0 0 0 0 0 0 0 0
        0 0 0 0 0 0 0 0 556 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 556 0 0 0 0 0
        0 0 611 ] >>
        endobj
        12 0 obj
        << /Type /FontDescriptor /FontName /AAAAAC+Helvetica /Flags 32 /FontBBox [-951 -481 1445 1122]
        /ItalicAngle 0 /Ascent 770 /Descent -230 /CapHeight 717 /StemV 0 /XHeight
        523 /AvgWidth 441 /MaxWidth 1500 /FontFile2 13 0 R >>
        endobj
        14 0 obj
        << /Producer (iOS Version 16.2 \(Build 20C52\) Quartz PDFContext) /Author
        (E-Rezept App 2) /CreationDate (D:20230413135905Z00'00') /ModDate (D:20230413135905Z00'00')
        >>
        endobj
        xref
        0 15
        0000000000 65535 f
        0000002565 00000 n
        0000005500 00000 n
        0000000022 00000 n
        0000002645 00000 n
        0000005465 00000 n
        0000005642 00000 n
        0000010356 00000 n
        0000002753 00000 n
        0000005593 00000 n
        0000006164 00000 n
        0000006408 00000 n
        0000010911 00000 n
        0000011150 00000 n
        0000016168 00000 n
        trailer
        << /Size 15 /Root 9 0 R /Info 14 0 R /ID [ <3298b0b748029f13ffa6cd9a22bbe8f3>
        <3298b0b748029f13ffa6cd9a22bbe8f3> ] >>
        startxref
        16353
        %%EOF

        """#

        let result = try PDFDocument.PDFDocumentParserPrinter().parse(input)

        expect(result.parts.count).to(equal(1))
        expect(result.parts.first?.objects.count).to(equal(10))
    }
}
