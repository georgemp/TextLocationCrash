//
//  DocumentModel.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import AppKit
import Logging

class DocumentModel: NSTextContentManager {
    var logger: Logger = {
        var logger = Logger(label: "in.roguemonkey.TextLocationCrash.DocumentModel")
        logger.logLevel = .debug

        return logger
    }()

    var layoutManager: NSTextLayoutManager!
    let renderingAttributes = RenderingAttributes()

    var currentEndLocation = Text.Location(line: 1, column: 1) {
        didSet {
            logger.debug("documentRange: \(documentRange)")
        }
    }

    let fullText = Text(text: """
First

Second

Third
""")

    func stepLocation() {
        var nextLocation = Text.Location(line: currentEndLocation.lineNumber, column: currentEndLocation.column + 1)
        if fullText[Text.Location(line: nextLocation.lineNumber, column: nextLocation.column - 1)] == "\n" {
            nextLocation = Text.Location(line: currentEndLocation.lineNumber + 1, column: 1)
        }

        currentEndLocation = nextLocation
    }



    override var documentRange: NSTextRange {
        let documentRange = NSTextRange(location: Text.Location(line: 1, column: 1), end: currentEndLocation)!

        return documentRange
    }

    func attach(textLayoutManager: NSTextLayoutManager) {
        self.layoutManager = textLayoutManager
        super.addTextLayoutManager(layoutManager)
    }

    func finalElementRanges() ->  [Range<Text.Location>] {
        var ranges = [Range<Text.Location>]()

        ranges.append(Text.Location(line: 1, column: 1)..<Text.Location(line: 3, column: 1))
        ranges.append(Text.Location(line: 3, column: 1)..<Text.Location(line: 5, column: 1))
        ranges.append(Text.Location(line: 5, column: 1)..<fullText.range.upperBound)

        return ranges
    }

    func finalElements() -> [NSTextElement] {
        var elements = [NSTextElement]()

        let finalElementRanges = self.finalElementRanges()

        for range in finalElementRanges {
            let text = fullText[range]
            let element = NSTextParagraph(attributedString: NSAttributedString(string: text, attributes: renderingAttributes.body.value))
            element.elementRange = NSTextRange(location: range.lowerBound, end: range.upperBound)
            elements.append(element)
        }

        return elements
    }

    // MARK: NSTextContentManager overrides
    override func textElements(for range: NSTextRange) -> [NSTextElement] {
        guard let rangeEndLocation = range.endLocation as? Text.Location else {
            return []
        }

        var textElements = [NSTextElement]()

        let finalElements = self.finalElements()
        let finalRanges = self.finalElementRanges()

        for (index, currentElementRange) in finalRanges.enumerated() {
            if rangeEndLocation > currentElementRange.upperBound {
                textElements.append(finalElements[index])
                continue
            }

            let range = currentElementRange.lowerBound..<rangeEndLocation
            let elementText = fullText[range]
            let element = NSTextParagraph(attributedString: NSAttributedString(string: elementText, attributes: renderingAttributes.body.value))
            element.elementRange = NSTextRange(location: range.lowerBound, end: range.upperBound)
            textElements.append(element)
            break
        }

        return textElements
    }

    // MARK: NSTextElementProvider Overrides
    override func enumerateTextElements(from textLocation: NSTextLocation?, options: NSTextContentManager.EnumerationOptions = [], using block: (NSTextElement) -> Bool) -> NSTextLocation? {
        var enumerationLocation = textLocation
        if enumerationLocation == nil {
            enumerationLocation = documentRange.location
        }

        guard let enumerationLocation = enumerationLocation as? Text.Location else {
            fatalError("Could not determine enumeration location")
        }

        let textElements = textElements(for: NSTextRange(location: enumerationLocation, end: documentRange.endLocation)!)
        var lastElement: NSTextElement?
        for textElement in textElements {
            lastElement = textElement
            logger.debug("enumerating textElement in range \(String(describing: textElement.elementRange)): \((textElement as! NSTextParagraph).attributedString.string.debugDescription)")
            if !block(textElement) {
                break
            }
        }

        let endLocation = lastElement?.elementRange?.endLocation

        return endLocation
    }

    override func location(_ location: NSTextLocation, offsetBy offset: Int) -> NSTextLocation? {
        guard let location = location as? Text.Location else {
            fatalError("Expected Text.Location")
        }

        let offsetLocation = fullText.location(location, offsetBy: offset)
        return offsetLocation
    }
    
    override func offset(from: NSTextLocation, to: NSTextLocation) -> Int {
        guard let start  = from as? Text.Location else {
            fatalError("Expected MarkupText.Location")
        }

        // For some reason, we are being passed a null pointer for `to` at times. Not sure how
        // If we can't cast to an valid MarkupText.Location, we will use the document's end location
        var end: Text.Location
        if let to = to as? Text.Location {
            end = to
        } else if let documentEnd = documentRange.endLocation as? Text.Location {
            end = documentEnd
        } else {
            fatalError("Could not determine end location for offset computation")
        }

        let offset = fullText.offset(from: start, to: end)
        return offset
    }
}
