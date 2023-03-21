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

final class PDFDocumentAppendTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParsingTestDocument1() throws {
        // tag::parseAndAttachToPdf[]
        // Parse the original PDF data and data to be attached
        let originalPdfData = try testResource(name: "simple_pdf", extension: "pdf")
        let toBeAttachedData = try testResource(name: "somedata", extension: "")

        // Parse the PDF data
        let originalPdfDataString = String(data: originalPdfData, encoding: .ascii)!.utf8
        let parsedPdfDocument = try PDFDocument.PDFDocumentParserPrinter().parse(originalPdfDataString)

        // Render the attachment data before appending
        let renderedAttachmentData = try parsedPdfDocument.append(
            attachment: .init(filename: "attachmentFilename🧸", content: toBeAttachedData),
            startObj:  originalPdfData.count
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
        // tag::extractAttachmentFromPdf[]
        let pdfWithAttachmentDataString = String(data: pdfWithAttachmentData, encoding: .ascii)!.utf8
        let parsedPdfWithAttachment = try PDFDocument.PDFDocumentParserPrinter().parse(pdfWithAttachmentDataString)
        let attachments = try parsedPdfWithAttachment.allAttachments()

        expect(attachments.count).to(equal(1)) // ✅
        expect(attachments.first?.content).to(equal(toBeAttachedData)) // ✅
        // end::extractAttachmentFromPdf[]
    }
}
