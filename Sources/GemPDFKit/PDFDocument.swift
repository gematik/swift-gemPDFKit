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

/// Structure representing the data container of a complete PDF file.
///
/// This structure implements the basics for chapter "3.4 File Structure" of the PDF 1.7 reference where
/// `PDFDocumentPart` serves as each 'body', 'cross-reference-table', 'trailer' occurrence.
public struct PDFDocument: Equatable {
    /// Version Header containing the pdf version
    public var version: String
    /// additional header, should contain binary ascii bytes
    public var header: String
    public var parts: [PDFDocumentPart] = [] {
        didSet {
            allObjects = parts.reduce(into: []) { $0 += $1.objects }
        }
    }

    init(version: String, header: String, parts: [PDFDocumentPart]) {
        self.version = version
        self.header = header
        self.parts = parts

        allObjects = parts.reduce(into: []) { $0 += $1.objects }
    }

    var allObjects: [PDFObject]
}

extension PDFDocument {
    struct VersionOrHeaderParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            "%".utf8
            Prefix { (element: Substring.UTF8View.Element) in
                element != "\n".utf8.first
            }.map(.string)
            "\n".utf8
        }
    }

    /// A Parser for a PDFDocument that conforms to (our subset of) PDF 1.7 and parses a whole Document
    public struct PDFDocumentParserPrinter: ParserPrinter {
        public init() {}

        public var body: some ParserPrinter<Substring.UTF8View, PDFDocument> {
            ParsePrint(.memberwise(PDFDocument.init(version:header:parts:))) {
                RawParserPrinter()
            }
        }

        private struct RawParserPrinter: ParserPrinter {
            // swiftlint:disable:next large_tuple
            var body: some ParserPrinter<Substring.UTF8View, (String, String, [PDFDocumentPart])> {
                VersionOrHeaderParserPrinter()
                VersionOrHeaderParserPrinter()

                Many {
                    PDFDocumentPart.PDFDocumentPartParserPrinter()
                }
            }
        }
    }
}

extension PDFDocument {
    /// Retrieves the last object that can be referenced by `reference`.
    ///
    /// As PDFDocuments can be updated incrementally, this method searches backwards through all existing objects and
    /// finds the first object that conformes to the given reference.
    public func objectBy(reference: PDFAtom) -> PDFObject? {
        guard case PDFAtom.reference = reference else {
            return nil
        }

        return allObjects.last { object in
            object.reference == reference
        }
    }

    func objectWithType(type: PDFAtom) -> PDFObject? {
        let objects = allObjects.filter { content in
            guard case let PDFAtom.dictionary(dictionary) = content.atom else {
                return false
            }

            return dictionary.first { (key: PDFAtom, value: PDFAtom) in
                PDFAtom.name("Type") == key && type == value
            } != nil
        }
        return objects.last
    }

    func maxId() -> Int {
        parts
            .reduce(into: []) { $0 += $1.objects.map(\.identifier) }
            .reduce(into: 0) { result, newValue in
                result = max(result, newValue)
            }
    }
}

extension String {
    static var bom = String(data: Data([0xFE, 0xFF]),
                            encoding: .utf16BigEndian)! // swiftlint:disable:this force_unwrapping
}

// swiftlint:disable function_body_length
extension PDFDocument {
    /// Renders a given `PDFAttachment` as data to append to existing PDF data.
    /// - Parameters:
    ///   - attachment: The attachment to append
    ///   - startObj: The length of the existing, rendered PDF data.
    /// - Returns: Data representing the rendered attachment
    public func append(
        attachment: PDFAttachment,
        startObj: Int
    ) throws -> Data {
        guard let startXRef = parts.first?.startXRef else {
            throw PDFDocumentError.emptyDocument
        }
        var objects: [PDFObject] = []
        var nextId = maxId() + 1
        let fileData = attachment.content
        let fileName = attachment.filename

        guard let pagesObject = objectWithType(type: .name("Pages")) else {
            throw PDFDocumentError.objectWithNameNotFound("Pages")
        }
        let pagesId = pagesObject.identifier

        guard let catalogObject = objectWithType(type: .name("Catalog")) else {
            throw PDFDocumentError.objectWithNameNotFound("Catalog")
        }
        let catalogId = catalogObject.identifier

        guard let dataStream = String(data: fileData, encoding: .utf8) else {
            return Data()
        }
        let stream = PDFObject(
            identifier: nextId,
            counter: 0,
            atom: .dictionary([
                .name("Length"): .int(dataStream.lengthOfBytes(using: .utf8)),
                .name("Params"): .dictionary([
                    .name("Size"): .int(dataStream.lengthOfBytes(using: .utf8)),
                ]),
            ]),
            stream: .init(stream: dataStream)
        )
        nextId += 1
        let filespec = PDFObject(
            identifier: nextId,
            counter: 0,
            atom: .dictionary([
                .name("Type"): .name("Filespec"),
                .name("UF"): .hexString("\(String.bom)\(fileName)"),
                .name("EF"): .dictionary([
                    .name("F"): .reference(stream.identifier, stream.counter),
                ]),
            ]),
            stream: nil
        )
        nextId += 1

        let names = PDFObject(
            identifier: nextId,
            counter: 0,
            atom: .dictionary([
                .name("Names"): .array([
                    .hexString("\(String.bom)\(fileName)"),
                    .reference(filespec.identifier, filespec.counter),
                ]),
            ]),
            stream: nil
        )

        let catalogAddition = PDFObject(
            identifier: catalogId,
            counter: 0,
            atom: .dictionary([
                .name("Type"): .name("Catalog"),
                .name("Pages"): .reference(pagesId, 0),
                .name("Names"): .dictionary([
                    .name("EmbeddedFiles"): .reference(nextId, 0),
                ]),
            ]),
            stream: nil
        )
        nextId += 1

        objects.append(catalogAddition)

        objects.append(stream)
        objects.append(filespec)
        objects.append(names)

        for object in objects {
            print(object)
        }

        let trailerContent = PDFAtom.dictionary([
            .name("Size"): .int(nextId),
            .name("Root"): .reference(catalogId, 0),
            .name("Prev"): .int(startXRef),
        ])

        let objectsData = try PDFDocumentPart.ObjectsParserPrinter().print(objects)

        let catalogData = try PDFObject.PDFObjectParserPrinter().print(catalogAddition)
        let streamData = try PDFObject.PDFObjectParserPrinter().print(stream)
        let filespecData = try PDFObject.PDFObjectParserPrinter().print(filespec)

        let xref = PDFXRef(sections: [
            .init(identifier: 0, count: 1, elements: [
                .init(startOffset: 1, generation: 65535, usage: .free),
            ]),
            .init(identifier: catalogId, count: 1, elements: [
                .init(startOffset: startObj, generation: 0, usage: .inUse),
            ]),
            .init(identifier: stream.identifier, count: 3, elements: [
                .init(startOffset: startObj + catalogData.count, generation: 0, usage: .inUse),
                .init(startOffset: startObj + catalogData.count + streamData.count, generation: 0, usage: .inUse),
                .init(
                    startOffset: startObj + catalogData.count + streamData.count + filespecData.count,
                    generation: 0,
                    usage: .inUse
                ),
            ]),
        ])

        let part = PDFDocumentPart(
            objects: objects,
            xref: xref,
            trailer: .init(body: trailerContent),
            startXRef: startObj + objectsData.count
        )

        guard let resultString = String(try PDFDocumentPart.PDFDocumentPartParserPrinter().print(part)),
              let result = resultString.data(using: .ascii) else {
            throw PDFDocumentError.failedToCreateStringFromPrintedObject
        }

        return result
    }
}
