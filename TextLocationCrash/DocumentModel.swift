//
//  DocumentModel.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import AppKit

class DocumentModel: NSTextContentManager {
    var layoutManager: NSTextLayoutManager!
    var data = ""

    override var documentRange: NSTextRange {
        NSTextRange(location: CustomTextLocation(column: 1), end: CustomTextLocation(column: 1))!
    }

    func attach(textLayoutManager: NSTextLayoutManager) {
        self.layoutManager = textLayoutManager
        super.addTextLayoutManager(layoutManager)
    }

    // MARK: NSTextContentManager overrides
    override func textElements(for range: NSTextRange) -> [NSTextElement] {
        [NSTextParagraph(textContentManager: self)]
    }

    // MARK: NSTextElementProvider Overrides
    override func enumerateTextElements(from textLocation: NSTextLocation?, options: NSTextContentManager.EnumerationOptions = [], using block: (NSTextElement) -> Bool) -> NSTextLocation? {
        guard let from = textLocation as? CustomTextLocation else {
            return nil
        }

        let textElements = textElements(for: NSTextRange(location: from, end: documentRange.endLocation)!)
        for textElement in textElements {
            let _ = block(textElement)
        }

        return documentRange.endLocation
    }

    override func offset(from: NSTextLocation, to: NSTextLocation) -> Int {
        guard let from = from as? CustomTextLocation,
              let to = to as? CustomTextLocation else {
            fatalError("Expected CustomTextLocation")
        }

        return to.column - from.column
    }
}
