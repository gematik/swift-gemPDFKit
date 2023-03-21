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

/// PDFAttachment represents a file that is or will be attached to a PDFDocument
public struct PDFAttachment {
    /// Filename of the attachment
    public let filename: String
    /// Content of the file
    public let content: Data

    /// Construct a `PDFAttachment` form data and a given filename
    public init(filename: String, content: Data) {
        self.filename = filename
        self.content = content
    }
}

// swiftlint:disable cyclomatic_complexity function_body_length cyclomatic_complexity
extension PDFDocument {
    /// Retrieves all file attachments from a given PDFDocument.
    public func allAttachments() throws -> [PDFAttachment] {
        guard let catalog = objectWithType(type: .name("Catalog")) else {
            throw PDFDocumentError.catalogNotFound
        }
        guard case let PDFAtom.dictionary(catalogDictionary) = catalog.atom else {
            throw PDFDocumentError.objectDoesNotContainDictionary(catalog)
        }
        guard let catalogDictionaryNamesDictionaryAtom = catalogDictionary[.name("Names")],
              case let PDFAtom.dictionary(catalogNamesDictionary) = catalogDictionaryNamesDictionaryAtom else {
            throw PDFDocumentError.namesEntryMissing
        }
        guard let embeddedFilesRef = catalogNamesDictionary[.name("EmbeddedFiles")] else {
            return [] // No embedded files
        }
        guard let embeddedFilesObject = objectBy(reference: embeddedFilesRef) else {
            throw PDFDocumentError.embeddedFilesObjectMissing
        }
        guard case let PDFAtom.dictionary(embeddedFilesDictionary) = embeddedFilesObject.atom else {
            throw PDFDocumentError.objectDoesNotContainDictionary(embeddedFilesObject)
        }
        guard let namesArrayAtom = embeddedFilesDictionary[.name("Names")],
              case let PDFAtom.array(namesArray) = namesArrayAtom,
              namesArray.count > 1 else {
            throw PDFDocumentError.namesArrayMissing
        }
        var index = 0

        var result: [PDFAttachment] = []
        while index < namesArray.count - 1 {
            let name = namesArray[index]
            let reference = namesArray[index + 1]

            guard let fileSpecObject = objectBy(reference: reference) else {
                throw PDFDocumentError.embeddedFilesObjectMissing
            }
            guard case let PDFAtom.dictionary(fileSpecObjectDictionary) = fileSpecObject.atom else {
                throw PDFDocumentError.objectDoesNotContainDictionary(fileSpecObject)
            }
            guard let dictionary = fileSpecObjectDictionary[.name("EF")],
                  case let PDFAtom.dictionary(fileSpecEFDict) = dictionary else {
                throw PDFDocumentError.missingEFDict
            }
            guard let fileReference = fileSpecEFDict[.name("F")],
                  let fileObject = objectBy(reference: fileReference) else {
                throw PDFDocumentError.missingEFFileReference
            }
            guard let data = fileObject.stream?.stream.data(using: .utf8) else {
                throw PDFDocumentError.fileObjectWithoutData
            }

            let fileName: String

            if case let PDFAtom.hexString(hexFileName) = name {
                fileName = hexFileName
            } else if case let PDFAtom.string(stringName) = name {
                fileName = stringName
            } else {
                fileName = "No Filename"
            }

            result.append(.init(filename: fileName, content: data))

            index += 2
        }

        return result
    }
}

enum PDFDocumentError: Error, Equatable {
    case emptyDocument
    case objectWithNameNotFound(String)
    case catalogNotFound
    case namesEntryMissing
    case objectDoesNotContainDictionary(PDFObject)
    case embeddedFilesObjectMissing
    case namesArrayMissing
    case missingEFDict
    case missingEFFileReference
    case fileObjectWithoutData
    case failedToCreateStringFromPrintedObject
}
