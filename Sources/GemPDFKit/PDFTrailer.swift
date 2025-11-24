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

public struct PDFTrailer: Equatable {
    public let body: PDFAtom

    init(body: PDFAtom) {
        self.body = body
    }
}

extension PDFTrailer {
    /// A Parser for a PDFDocument that conforms to (our subset of) PDF 1.7 and parses a single 'trailer'
    public struct PDFTrailerParserPrinter: ParserPrinter {
        public var body: some ParserPrinter<Substring.UTF8View, PDFTrailer> {
            ParsePrint(.memberwise(PDFTrailer.init(body:))) {
                RawParserPrinter()
            }
        }
    }

    private struct RawParserPrinter: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, PDFAtom> {
            "trailer\n".utf8
            PDFAtom.parser
            OneOf {
                Whitespace()
                "\n".utf8
            }
        }
    }
}
