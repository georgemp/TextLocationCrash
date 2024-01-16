//
//  RenderingAttributes.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/01/24.
//

import AppKit

internal extension NSFont {
    func withTraitsAdded(_ symbolicTraits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
        let fd = fontDescriptor.withSymbolicTraits(symbolicTraits)

        return NSFont(descriptor: fd, size: pointSize)
    }

    func withTraitsRemoved(_ symbolicTraits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
        var myTraits = fontDescriptor.symbolicTraits
        guard let _ = myTraits.remove(symbolicTraits) else {
            return nil
        }
        let fd = fontDescriptor.withSymbolicTraits(myTraits)
        let newFont = NSFont(descriptor: fd, size: pointSize)
        return newFont
    }
}
struct FontBuilder {
    var value: NSFont

    init(base: NSFont) {
        value = base
    }

    mutating func addTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        if let newFont = value.withTraitsAdded(trait) {
            value = newFont
        }
    }

    mutating func removeTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        if let newFont = value.withTraitsRemoved(trait) {
            value = newFont
        }
    }
}

struct AttributedFontBuilder {
    private var fontBuilder: FontBuilder
    private var attributes = [NSAttributedString.Key: Any]()

    var value: [NSAttributedString.Key: Any] {
        var attributes = self.attributes
        attributes[.font] = fontBuilder.value

        return attributes
    }

    init(withBaseFont base: NSFont, attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key: Any]()) {
        self.fontBuilder = .init(base: base)
        self.attributes = attributes
    }

    mutating func addFontTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        fontBuilder.addTrait(trait)
    }

    mutating func removeFontTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        fontBuilder.removeTrait(trait)
    }

    mutating func setAttribute(withKey key: NSAttributedString.Key, value: Any) {
        attributes[key] = value
    }

    mutating func removeAttribute(withKey key: NSAttributedString.Key) {
        attributes.removeValue(forKey: key)
    }

    /// This method assigns the current traits (bold, italic) to the new font before switching it out in the attributes dictionary.
    mutating func switchFont(_ newFont: NSFont) {
        let currentTraits = fontBuilder.value.fontDescriptor.symbolicTraits

        if let font = newFont.withTraitsAdded(currentTraits) {
            fontBuilder = FontBuilder(base: font)
        }
    }
}

struct RenderingAttributes {
    var body: AttributedFontBuilder
    var code: AttributedFontBuilder
    var controlCharacters : AttributedFontBuilder

    init(body: NSFont, code: NSFont, controlCharacters: NSFont) {
        self.body = AttributedFontBuilder(withBaseFont: body)
        self.code = AttributedFontBuilder(withBaseFont: code)
        self.controlCharacters = AttributedFontBuilder(withBaseFont: controlCharacters)
    }

    init() {
        //TODO: Bundle Roboto font with app
        var bodyFont: NSFont! = NSFont(name: "Roboto", size: 15)
        if bodyFont == nil {
            bodyFont = .userFont(ofSize: 15) ?? .systemFont(ofSize: 15)
        }

        var codeFont: NSFont! = NSFont(name: "RobotoMono-Regular", size: 15)
        if codeFont == nil {
            codeFont = .monospacedSystemFont(ofSize: 15, weight: .regular)
        }

        var controlCharactersFont: NSFont! = NSFont(name: "RobotoMono-Medium", size: 15)
        if controlCharactersFont == nil {
            controlCharactersFont = .monospacedSystemFont(ofSize: 15, weight: .bold)
        }

        self.init(body: bodyFont, code: codeFont, controlCharacters: controlCharactersFont)

        self.controlCharacters.setAttribute(withKey: .foregroundColor, value: NSColor.lightGray.cgColor)
    }
}


