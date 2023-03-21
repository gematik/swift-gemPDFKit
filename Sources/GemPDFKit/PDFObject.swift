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

public struct PDFObject: Equatable {
    let identifier: Int
    let counter: Int
    let atom: PDFAtom
    let stream: PDFStream?

    var reference: PDFAtom { .reference(identifier, counter) }

    init(identifier: Int, counter: Int, atom: PDFAtom, stream: PDFStream?) {
        self.identifier = identifier
        self.counter = counter
        self.atom = atom
        self.stream = stream
    }
}

struct PDFStream: Equatable {
    var stream: String
}

extension PDFStream {
    struct PDFStreamParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFStream> {
            ParsePrint(.memberwise(PDFStream.init)) {
                RawParserPrinter()
            }
        }

        struct RawParserPrinter: ParserPrinter {
            var body: some ParserPrinter<Substring.UTF8View, String> {
                OneOf {
                    Whitespace()
                    "\n".utf8
                }
                "stream\n".utf8
                PrefixUpTo("\nendstream\n".utf8).map(.string)
                "\nendstream\n".utf8
            }
        }
    }
}

extension PDFObject {
    /// A Parser for a PDFDocument that conforms to (our subset of) PDF 1.7 and parses a single Object of a PDF document
    public struct PDFObjectParserPrinter: ParserPrinter {
        public var body: some ParserPrinter<Substring.UTF8View, PDFObject> {
            ParsePrint(.memberwise(PDFObject.init(identifier:counter:atom:stream:))) {
                RawParserPrinter()
            }
        }

        private struct RawParserPrinter: ParserPrinter {
            // swiftlint:disable:next large_tuple
            var body: some ParserPrinter<Substring.UTF8View, (Int, Int, PDFAtom, PDFStream?)> {
                Int.parser()
                " ".utf8
                Int.parser()
                " obj\n".utf8
                //
                PDFAtom.parser

                Optionally {
                    Whitespace()

                    PDFStream.PDFStreamParserPrinter()
                }

                OneOf {
                    Whitespace()
                    "\n".utf8
                }

                "endobj\n".utf8
            }
        }
    }
}
