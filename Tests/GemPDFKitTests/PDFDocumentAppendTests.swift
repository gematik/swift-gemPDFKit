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

final class PDFDocumentAppendTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAddingNothingWorks() throws {
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")

        let originalPdfDataString = String(data: originalPdfData, encoding: .isoLatin1)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        var document = parsedPdfDocument
        // Append no attachments
        let attachmentsData = try document.append(attachments: [], startObj: originalPdfData.count)
        // Check that no data was appended
        expect(attachmentsData).to(beEmpty())
    }

    func testAppendingComplex() throws {
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")

        let testData = try testResource(name: "somedata", extension: "")

        let originalPdfDataString = String(data: originalPdfData, encoding: .isoLatin1)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        let attachments: [PDFAttachment] = [
            // Verordnungsdatensatz
            PDFAttachment(
                filename: "200.000.002.450.751.30_verordnung.p7s",
                content: testData
            ),
            PDFAttachment(
                filename: "200.000.002.450.751.30_abgabedaten.p7s",
                content: testData
            ),
            PDFAttachment(
                filename: "200.000.002.450.751.30_quittung.p7s",
                content: testData
            ),
            PDFAttachment(
                filename: "200.000.002.450.751.30_quittung3.p7s",
                content: testData
            ),
        ]

        var result = originalPdfData

        let attachementsData = try! parsedPdfDocument.append(attachments: attachments, startObj: originalPdfData.count)
        result.append(attachementsData)

        // This is for manual validation:
        let compare = outputResourceURL(name: "output", extension: "pdf")
        try result.write(to: compare)

        let pdfWithAttachmentDataString = String(data: result, encoding: .isoLatin1)!.utf8
        let parsedPdfWithAttachment = try PDFDocument.PDFDocumentParserPrinter().parse(pdfWithAttachmentDataString)
        let reparsedAttachments = try parsedPdfWithAttachment.allAttachments()

        expect(reparsedAttachments.count).to(equal(4)) // ✅
    }

    func testParsingTestDocument1() throws {
        // Parse the original PDF data and data to be attached
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")
        let toBeAttachedData = try testResource(name: "somedata", extension: "")

        // Parse the PDF data
        let originalPdfDataString = String(data: originalPdfData, encoding: .isoLatin1)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        // Render the attachment data before appending
        let renderedAttachmentData = try parsedPdfDocument.append(
            attachment: .init(filename: "attachmentFilename🧸", content: toBeAttachedData),
            startObj: originalPdfData.count
        )

        // Add the rendered attachment data to the original PDF data
        let pdfWithAttachmentData = originalPdfData + renderedAttachmentData

        // Write the data to your system
        let outputPath = outputResourceURL(name: "output", extension: "pdf")
        try pdfWithAttachmentData.write(to: outputPath)

        // This is for manual validation:
        let compare = outputResourceURL(name: "compare", extension: "pdf")
        try renderedAttachmentData.write(to: compare)

        // Extract the test data
        // tag::extractAttachmentFromPdf[]
        let pdfWithAttachmentDataString = String(data: pdfWithAttachmentData, encoding: .isoLatin1)!.utf8
        let parsedPdfWithAttachment = try PDFDocument.PDFDocumentParserPrinter().parse(pdfWithAttachmentDataString)
        let attachments = try parsedPdfWithAttachment.allAttachments()

        expect(attachments.count).to(equal(1)) // ✅
        expect(attachments.first?.content).to(equal(toBeAttachedData)) // ✅
        // end::extractAttachmentFromPdf[]
    }

    func testParsingTestDocument2() throws {
        // tag::parseAndAttachToPdf[]
        // Parse the original PDF data and data to be attached
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")
        let toBeAttachedData = try testResource(name: "somedata", extension: "")

        // Parse the PDF data
        let originalPdfDataString = String(data: originalPdfData, encoding: .isoLatin1)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        // Render the attachment data before appending
        let renderedAttachmentData = try parsedPdfDocument.append(
            attachments: [.init(filename: "attachmentFilename🧸", content: toBeAttachedData)],
            startObj: originalPdfData.count
        )

        // Add the rendered attachment data to the original PDF data
        let pdfWithAttachmentData = originalPdfData + renderedAttachmentData

        // Write the data to your system
        let outputPath = outputResourceURL(name: "output", extension: "pdf")
        try pdfWithAttachmentData.write(to: outputPath)
        // end::parseAndAttachToPdf[]

        // This is for manual validation:
        let compare = outputResourceURL(name: "compare", extension: "pdf")
        try renderedAttachmentData.write(to: compare)

        // Extract the test data
        let pdfWithAttachmentDataString = String(data: pdfWithAttachmentData, encoding: .isoLatin1)!.utf8
        let parsedPdfWithAttachment = try PDFDocument.PDFDocumentParserPrinter().parse(pdfWithAttachmentDataString)
        let attachments = try parsedPdfWithAttachment.allAttachments()

        expect(attachments.count).to(equal(1)) // ✅
        expect(attachments.first?.content).to(equal(toBeAttachedData)) // ✅
    }

    func testParsingTestDocument3() throws {
        // Parse the original PDF data and data to be attached
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")
        let toBeAttachedData = try testResource(name: "somedata", extension: "")
        let toBeAttachedData2 = try testResource(name: "somedata2", extension: "")

        // Parse the PDF data
        let originalPdfDataString = String(data: originalPdfData, encoding: .isoLatin1)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        // Render the attachment data before appending
        let renderedAttachmentData = try parsedPdfDocument.append(attachments: [
            .init(filename: "a_somedata", content: toBeAttachedData),
            .init(filename: "b_somedata", content: toBeAttachedData2),
        ], startObj: originalPdfData.count)

        // Add the rendered attachment data to the original PDF data
        let pdfWithAttachmentData = originalPdfData + renderedAttachmentData

        // Write the data to your system
        let outputPath = outputResourceURL(name: "output", extension: "pdf")
        try pdfWithAttachmentData.write(to: outputPath)

        // This is for manual validation:
        let compare = outputResourceURL(name: "compare", extension: "pdf")
        try renderedAttachmentData.write(to: compare)

        // Extract the test data
        let pdfWithAttachmentDataString = String(data: pdfWithAttachmentData, encoding: .isoLatin1)!.utf8
        let parsedPdfWithAttachment = try PDFDocument.PDFDocumentParserPrinter().parse(pdfWithAttachmentDataString)
        let attachments = try parsedPdfWithAttachment.allAttachments()

        expect(attachments.count).to(equal(2)) // ✅
        expect({
            attachments.sorted { left, right in
                left.filename < right.filename
            }
            .map(\.content)
        }).to(equal([toBeAttachedData, toBeAttachedData2])) // ✅
    }
}
