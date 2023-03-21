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

public struct PDFDocumentPart: Equatable {
    public var objects: [PDFObject]
    public var xref: PDFXRef
    public var trailer: PDFTrailer
    public var startXRef: Int
}

extension PDFDocumentPart {
    struct ObjectsParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, [PDFObject]> {
            Many {
                PDFObject.PDFObjectParserPrinter()
            }
        }
    }

    /// A Parser for a PDFDocument that conforms to (our subset of) PDF 1.7 and parses a single Document Part
    public struct PDFDocumentPartParserPrinter: ParserPrinter {
        public var body: some ParserPrinter<Substring.UTF8View, PDFDocumentPart> {
            ParsePrint(.memberwise(PDFDocumentPart.init(objects:xref:trailer:startXRef:))) {
                RawParserPrinter()
            }
        }

        struct RawParserPrinter: ParserPrinter {
            // swiftlint:disable:next large_tuple
            public var body: some ParserPrinter<Substring.UTF8View, ([PDFObject], PDFXRef, PDFTrailer, Int)> {
                ObjectsParserPrinter()

                PDFXRef.XRefParserPrinter()

                PDFTrailer.PDFTrailerParserPrinter()

                "startxref\n".utf8
                Int.parser()
                "\n".utf8
                "%%EOF\n".utf8
            }
        }
    }
}
