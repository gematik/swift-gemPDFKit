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
import Parsing

public struct PDFXRef: Equatable {
    public let sections: [Section]

    init(sections: [Section]) {
        self.sections = sections
    }

    public struct Section: Equatable {
        public var identifier: Int
        public var count: Int

        public var elements: [ObjectReference]

        public struct ObjectReference: Equatable {
            public var startOffset: Int

            public var generation: Int

            public var usage: Usage

            public enum Usage: Equatable {
                case free
                case inUse
            }
        }
    }
}

extension PDFXRef {
    struct SectionObjectReferenceParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFXRef.Section.ObjectReference> {
            ParsePrint(.memberwise(PDFXRef.Section.ObjectReference.init(startOffset:generation:usage:))) {
                RawParserPrinter()
            }
        }

        // Compiler Performance Workaround
        private struct RawParserPrinter: ParserPrinter {
            // swiftlint:disable:next large_tuple
            var body: some ParserPrinter<Substring.UTF8View, (Int, Int, PDFXRef.Section.ObjectReference.Usage)> {
                Digits(10)
                " ".utf8
                Digits(5)
                " ".utf8
                SectionUsageParser()
                SectionEndParser()
            }
        }

        struct SectionEndParser: ParserPrinter {
            var body: some ParserPrinter<Substring.UTF8View, Void> {
                OneOf {
                    "\n".utf8
                    " \n".utf8
                }
            }
        }

        struct SectionUsageParser: ParserPrinter {
            var body: some ParserPrinter<Substring.UTF8View, PDFXRef.Section.ObjectReference.Usage> {
                OneOf {
                    "f".utf8.map(.case(PDFXRef.Section.ObjectReference.Usage.free))
                    "n".utf8.map(.case(PDFXRef.Section.ObjectReference.Usage.inUse))
                }
            }
        }
    }

    struct SectionParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFXRef.Section> {
            ParsePrint(.memberwise(PDFXRef.Section.init(identifier:count:elements:))) {
                RawParserPrinter()
            }
        }

        private struct RawParserPrinter: ParserPrinter {
            // swiftlint:disable:next large_tuple
            var body: some ParserPrinter<Substring.UTF8View, (Int, Int, [PDFXRef.Section.ObjectReference])> {
                Int.parser()
                " ".utf8
                Int.parser()
                "\n".utf8
                Many {
                    SectionObjectReferenceParserPrinter()
                }
            }
        }
    }

    /// A Parser for a XRef that conforms to (our subset of) PDF 1.7 and parses a single xref Section of a PDFDocument
    struct XRefParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFXRef> {
            ParsePrint(.memberwise(PDFXRef.init(sections:))) {
                "xref\n".utf8
                Many {
                    SectionParserPrinter()
                }
            }
        }
    }
}
