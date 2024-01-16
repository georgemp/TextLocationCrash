//
//  Text.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 18/12/23.
//

import Foundation

import Foundation
import Tagged
import AppKit

/// `Text` is a collection of `Line`s. Each line (except for the last one) will have a trailing  '\n' in it's content
public struct Text: RandomAccessCollection {
    /// `Text` is indexed by `LineNumber`.  The index of the first possible valid line. The minimum index value is 1. If content is empty, then both `startIndex` and `endIndex` will be 1.
    public var startIndex: LineNumber {
        LineNumber(lines.startIndex + 1)
    }

    /// The index of the last valid line.
    public var endIndex: LineNumber {
        LineNumber(lines.endIndex + 1)
    }

    public enum LineNumberTag {}
    /// A Integer wrapper that repersents the number of the line in our text content. Each line is a string that ends with '\n'.
    public typealias LineNumber = Tagged<LineNumberTag, Int>

    public enum LineTag {}
    /// A string wrapper that represents a line in our text content. It is expected that a `Line` will have only one newline ('\n') character. If present, this newline should terminate the content. Semantically, when this is used in conjunction with `Text`, only the last `Line` can possibly not be terminated by a newline.
    public typealias Line = Tagged<LineTag, String>

    /// `Location` represents a position in our text. It is formed by combining a `LineNumber` and a `Line.Column`
    public class Location: NSObject {
        let lineNumber: LineNumber
        let column: Line.Column

        init(line: LineNumber, column: Line.Column) {
            self.lineNumber = line
            self.column = column
        }

        override public func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? Location else {
                return false
            }

            return self.lineNumber == object.lineNumber && self.column == object.column
        }


//        override public var hash: Int {
//            var hasher = Hasher()
//            hasher.combine(self.lineNumber)
//            hasher.combine(self.column)
//
//            return hasher.finalize()
//        }

        override public var description: String {
            "(\(lineNumber), \(column))"
        }
    }

    fileprivate var lines: [Line]

    public var isEmpty: Bool {
        lines.isEmpty || lines[0].isEmpty
    }

    init(text: String) {
        self.lines = toLines(text)
    }

    public var numberOfLines: Int {
        lines.count
    }

    public subscript(index: LineNumber) -> Line {
        get {
            lines[index.arrayIndex]
        }
        set(newValue) {
            lines[index.arrayIndex] = newValue
        }
    }

    subscript(bounds: Range<LineNumber>) -> ArraySlice<Line> {
        get {
            lines[bounds.lowerBound.arrayIndex..<(bounds.upperBound.arrayIndex)]
        }
        set(newValue) {
            lines[bounds.lowerBound.arrayIndex..<(bounds.upperBound.arrayIndex)] = newValue
        }
    }

    subscript(bounds: PartialRangeFrom<LineNumber>) -> ArraySlice<Line> {
        get {
            lines[bounds.lowerBound.arrayIndex...]
        }
        set(newValue) {
            lines[bounds.lowerBound.arrayIndex...] = newValue
        }
    }

    subscript(bounds: PartialRangeUpTo<LineNumber>) -> ArraySlice<Line> {
        get {
            lines[..<bounds.upperBound.arrayIndex]
        }
        set(newValue) {
            lines[..<bounds.upperBound.arrayIndex] = newValue
        }
    }

    subscript(bounds: PartialRangeThrough<LineNumber>) -> ArraySlice<Line> {
        get {
            lines[...bounds.upperBound.arrayIndex]
        }
        set(newValue) {
            lines[...bounds.upperBound.arrayIndex] = newValue
        }
    }

    subscript(index: Location) -> Character {
        let line = self[index.lineNumber]
        return line[index.column]
    }

    subscript(bounds: Range<Location>) -> String {
        substring(with: bounds)
    }

    var firstLine: Line? {
        lines.first
    }

    var lastLine: Line? {
        lines.last
    }

    /// Combines all our content lines into a single string.
    var rawText: String {
        lines.map { $0.rawValue }.joined()
    }

    /// A range repsented by the first and last valid locations in our document. The last location is represented by a column that is oen more than the last valid column in the last line.
    var range: Range<Location> {
        let start = Location(line: 1, column: 1)
        let end: Location
        if lines.isEmpty {
            end = Location(line: 1, column: 1)
        } else {
            end = Location(line: LineNumber(lines.count), column: Line.Column(lastLine!.utf8.count + 1))
        }

        return start..<end
    }

    /// Appends  a new `Line` to our contents
    ///
    /// - Parameters:
    ///  - line: New line to append
    mutating func push(line: Line) {
        lines.append(line)
    }

    /// Inserts a new `Line` as specified index. If `Line` is not to be the last line, then it must terminate with a '\n'.
    /// - Parameters:
    ///  - line: `Line` to insert
    ///  - index: Position at which to insert the line. Line is inserted right before this index.
    mutating func insert(line: Line, at index: LineNumber) {
        lines.insert(line, at: index.arrayIndex)
    }

    /// Removes a line form our contents
    ///
    /// - Parameters:
    ///  - index: `LineNumber` to remove. It has to be a valid index.
    ///
    /// - Returns: The `Line` that was removed.
    mutating func removeLine(at index: LineNumber) -> Line {
        lines.remove(at: index.arrayIndex)
    }

    private func substring(with range: Range<Location>) -> String {
        var substring: String
        if range.lowerBound.lineNumber == range.upperBound.lineNumber {
            let line = self[range.lowerBound.lineNumber]
            substring = String(line[range.lowerBound.column..<range.upperBound.column])
        } else {
            substring = String()

            let firstLine = self[range.lowerBound.lineNumber]
            substring.append(String(firstLine[range.lowerBound.column...]))

            if range.upperBound.lineNumber - range.lowerBound.lineNumber > 1 {
                let midSectionStart = range.lowerBound.lineNumber + 1
                let midSectionEnd = range.upperBound.lineNumber

                for line in self[midSectionStart..<midSectionEnd] {
                    substring.append(line.rawValue)
                }
            }

            let lastLine = self[range.upperBound.lineNumber]
            substring.append(String(lastLine[..<range.upperBound.column]))
        }

        return substring
    }

    /// Returns a location that is offset by a number of utf8 codepoints.
    ///
    /// - Parameters:
    ///  - location: Starting location to begin the calculation. Must be a valid location
    ///  - offsetBy: The number of utf8 codepoints the starting location needs to be offset by. It needs to be a positive value.
    ///
    /// - Returns: A location that offsets `location` by `offsetBy` codepoints. Returns nil if the offset is out of bounds.
    public func location(_ location: Location, offsetBy offset: Int) -> Location? {
        var lineNumber = location.lineNumber

        var offsetBy = offset
        var line = self[lineNumber]
        var startColumn = location.column.rawValue
        var utf8 = line.utf8
        while offsetBy > utf8.count - startColumn {
            if (lineNumber + 1).rawValue > lines.count {
                // We are at the last line. Check if offset ends at End of Document position, else offset is outside document bounds
                if startColumn + offsetBy == (utf8.count + 1) {
                    break
                }

                return nil
            }

            offsetBy -= utf8.count - startColumn
            lineNumber += 1
            startColumn = 0
            line = self[lineNumber]
            utf8 = line.utf8
        }

        let column = startColumn + offsetBy
        return Location(line: lineNumber, column: Line.Column(column))
    }

    /// This offsets by number of characters (not utf8 codepoints - for example, é would take up two utf8 codepoints. But, only 1 character. To offset by character count, we need to work on the original string (and not the UTF8 view. Assuming the original string is indexed by character). UTF8-view seems to be indexed by code points (evidenced by following code sample)

    /// ```
    /// let value = "é"
    /// print("\(value.indices.count)") //  1
    /// print("\(value.utf8.indices.count)") // 2
    /// ```
    ///
    /// - Parameters:
    ///  - location: Starting `Location` in our text content
    ///  - offset: The number of characters to offset by
    ///
    /// - Returns: A new location that represents the starting location offset by a the given number of characters. Returns `nil` if out of bounts.
    ///
    public func location(_ location: Location, offsetByCharacterCount offset: Int) -> Location? {
        var lineNumber = location.lineNumber

        var line = self[lineNumber]
        var iteratedIndex = line.stringIndex(for: location.column)
        var iterNumber = 0
        while iterNumber < offset {
            iteratedIndex = line.index(after: iteratedIndex)
            iterNumber += 1
            if iteratedIndex == line.endIndex {
                lineNumber += 1
                if lineNumber.rawValue > lines.count {
                    return nil
                }
                line = self[lineNumber]
                iteratedIndex = line.startIndex
            }
        }

        let column = line.utf8.distance(from: line.startIndex, to: iteratedIndex) + 1
        let location = Location(line: lineNumber, column: Line.Column(column))

        return location
    }

    /// Computes the offset in utf8 codepoints between two `Location`s. This method assumes from and to are valid locations. Else, an invalid value might be returned
    ///
    /// - Parameters:
    ///  - from: The starting `Location` to begin computation
    ///  - to: The ending `Location` for the computation. The computation is inclusive of this ending location
    ///
    /// - Returns: The number of utf8 codepoints between two locations. If `to` is  > `from` the offset is negative.
    ///
    public func offset(from: Location, to: Location) -> Int {
        if from == to {
            return 0
        }

        var offset = 0
        var from = from
        var to = to

        var shouldMakeNegative = false
        if to < from {
            let temp = to
            to = from
            from = temp
            shouldMakeNegative = true
        }

        if from.lineNumber == to.lineNumber {
            offset = to.column.rawValue - from.column.rawValue
        } else {
            for lineNumber in from.lineNumber...to.lineNumber {
                let line = self[lineNumber]
                if lineNumber == from.lineNumber {
                    // Increment offset from start position to end of line
                    offset += line.utf8Count - from.column.rawValue
                } else if lineNumber == to.lineNumber {
                    // Increment offset from start position to to.column
                    offset += to.column.rawValue
                } else {
                    offset += line.utf8Count
                }
            }
        }

        return shouldMakeNegative ? -(offset) : offset
    }
}

extension Text: Equatable {
    public static func ==(lhs: Text, rhs: Text) -> Bool {
        return lhs.lines == rhs.lines
    }
}

extension Text.Line {
    public enum ColumnTag {}
    /// Column is a wrapper to swift-mardown's column in a `Line`. It maps to utf8 offset bytes.
    public typealias Column = Tagged<ColumnTag, Int>

    /// The starting string index (in the utf8 view of wrapped `String`).
    public var utf8StartIndex: String.Index {
        self.rawValue.utf8.startIndex
    }

    /// The ending string index (in the utf8 view of wrapped `String`).
    public var utf8EndIndex: String.Index {
        self.rawValue.utf8.endIndex
    }

    /// The number of utf8 codepoints in the wrapped `String`.
    public var utf8Count: Int {
        self.rawValue.utf8.count
    }

    /// `true` if our content is empty
    public var isEmpty: Bool {
        rawValue.isEmpty
    }

    /// `true` if our content comprises of a single `\n` character.
    public var isNewLine: Bool {
        rawValue.elementsEqual("\n")
    }

    /// Returns the utf8 index in wrapped string.
    ///
    /// - Parameters:
    ///  - for: The column location in our text (measured in uft8 codepoints), for which we are to get the correspoding `String.Index`. The column maps to swift-markdown's `SourceLocation.Column`
    public func stringIndex(for column: Column) -> String.Index {
        let utf8 = self.rawValue.utf8
        return utf8.index(utf8.startIndex, offsetBy: column.zeroIndex)
    }

    public subscript(index: Column) -> Character {
        let index = stringIndex(for: index)
        return self.rawValue[index]
    }

    public subscript(bounds: PartialRangeFrom<Column>) -> Substring {
        let index = stringIndex(for: bounds.lowerBound)
        return self.rawValue[index...]
    }

    public subscript(bounds: PartialRangeUpTo<Column>) -> Substring {
        get {
            let index = stringIndex(for: bounds.upperBound)
            return self.rawValue[..<index]
        }
    }

    public subscript(bounds: PartialRangeThrough<Column>) -> Substring {
        get {
            let index = stringIndex(for: bounds.upperBound)
            return self.rawValue[...index]
        }
    }

    public subscript(bounds: Range<Column>) -> Substring {
        get {
            let lowerBound = stringIndex(for: bounds.lowerBound)
            let upperBound = stringIndex(for: bounds.upperBound)

            return self.rawValue[lowerBound..<upperBound]
        }
    }

    public subscript(bounds: ClosedRange<Column>) -> Substring {
        // Do not reuse bounds: Range<Column> via incrementing upper bound by 1 to implement this.
        // We might be tempted to convert range 2...10 to 2..<11 and reuse the implementation of Range.
        // But consider those ranges with text is "Line has é and e.".
        // 2...10 should be "ine has é"
        // But. 2..<11 is ""ine has "
        let lowerBound = stringIndex(for: bounds.lowerBound)
        let upperBound = stringIndex(for: bounds.upperBound)

        return self.rawValue[lowerBound...upperBound]
    }

    /// Appends the contents of a `String` to our content.
    ///
    /// - Parameters:
    ///  - other: String to append
    ///
    public mutating func append(_ other: String) {
        self.rawValue.append(other)
    }

    /// Appends a `Character` to our content.
    ///
    /// - Parameters:
    ///  - _: `Character` to append
    public mutating func append(_ c: Character) {
        self.rawValue.append(c)
    }

    /// Appends the contents of `String` to our content.
    ///
    /// - Parameters:
    ///  - contentsOf: `String` to append
    public mutating func append(contentsOf newElements: String) {
        self.rawValue.append(contentsOf: newElements)
    }

    /// Appends the contents of `Substring` to our content.
    ///
    /// - Parameters:
    ///  - contentsOf: `Substring` to append
    public mutating func append(contentsOf newElements: Substring) {
        self.rawValue.append(contentsOf: newElements)
    }

    /// Appends the contents of a sequence to our content. The `Element`s  of the `Sequence` must be of type `Character`.
    ///
    /// - Parameters:
    ///  - contentsOf: `Seequnce` of `Character` to append
    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, S.Element == Character {
        self.rawValue.append(contentsOf: newElements)
    }

    /// Removes the content in a specified range,
    ///
    /// - Parameters:
    ///  - _: `Range<Column>` to remove from our contents.
    public mutating func removeSubrange(_ bounds: Range<Column>) {
        let lowerBound = stringIndex(for: bounds.lowerBound)
        let upperBound = stringIndex(for: bounds.upperBound)

        self.rawValue.removeSubrange(lowerBound..<upperBound)
    }

    public mutating func removeSubrange(_ bounds: PartialRangeFrom<Column>) {
        let lowerBound = stringIndex(for: bounds.lowerBound)
        self.rawValue.removeSubrange(lowerBound...)
    }

    public mutating func removeSubrange(_ bounds: PartialRangeUpTo<Column>) {
        let upperBound = stringIndex(for: bounds.upperBound)
        self.rawValue.removeSubrange(..<upperBound)
    }

    public mutating func removeSubrange(_ bounds: PartialRangeThrough<Column>) {
        let upperBound = stringIndex(for: bounds.upperBound)
        self.rawValue.removeSubrange(...upperBound)
    }

    // The following set of replace functions work correctly only if newElements is on a single line (does not have newlines). Otherwise, our contents will no longer be restricted to a single line.
    public mutating func replaceSubrange<C>(_ subrange: Range<Column>, with newElements: C) where C : Collection, C.Element == Character {
        let lowerBound = stringIndex(for: subrange.lowerBound)
        let upperBound = stringIndex(for: subrange.upperBound)
        self.rawValue.replaceSubrange(lowerBound..<upperBound, with: newElements)
    }

    public mutating func replaceSubrange<C>(_ subrange: PartialRangeFrom<Column>, with newElements: C) where C : Collection, C.Element == Character {
        let lowerBound = stringIndex(for: subrange.lowerBound)
        self.rawValue.replaceSubrange(lowerBound..., with: newElements)
    }

    public mutating func replaceSubrange<C>(_ subrange: PartialRangeUpTo<Column>, with newElements: C) where C : Collection, C.Element == Character {
        let upperBound = stringIndex(for: subrange.upperBound)
        self.rawValue.replaceSubrange(..<upperBound, with: newElements)
    }

    public mutating func replaceSubrange<C>(_ subrange: PartialRangeThrough<Column>, with newElements: C) where C : Collection, C.Element == Character {
        let upperBound = stringIndex(for: subrange.upperBound)
        self.rawValue.replaceSubrange(...upperBound, with: newElements)
    }

    public mutating func popLast() -> Character? {
        self.rawValue.popLast()
    }

    /// Checks if the specfied column is the last column in our content.
    /// - Parameters:
    ///  - column: The `Column` to check. It must be a valid column in our string and is measured in utf8 codepoints.
    public func isLast(column: Column) -> Bool {
        let utf8 = rawValue.utf8
        let columnIndex = stringIndex(for: column)
        let nextIndex = utf8.index(after: columnIndex)
        if nextIndex == utf8.endIndex {
            return true
        }

        return false
    }

    public func trailingWhitespace() -> String? {
        var whiteSpaceEnd: String.Index?
        var whiteSpaceBegin = self.rawValue.startIndex
        for index in self.rawValue.indices.reversed() {
            let char = self.rawValue[index]
            if char.isNewline {
                continue
            }

            if !char.isWhitespace {
                break
            }

            if whiteSpaceEnd == nil {
                whiteSpaceEnd = index
                whiteSpaceBegin = index
            } else {
                whiteSpaceBegin = index
            }
        }

        return whiteSpaceEnd.map {
            String(self.rawValue[whiteSpaceBegin...$0])
        }
    }

    public func leadingWhitespace() -> String? {
        var whiteSpaceBegin: String.Index?
        var whiteSpaceEnd: String.Index?

        for index in self.rawValue.indices {
            let char = self.rawValue[index]
            if char.isNewline || !char.isWhitespace {
                break
            }

            if whiteSpaceBegin == nil {
                whiteSpaceBegin = index
                whiteSpaceEnd = index
            } else {
                whiteSpaceEnd = index
            }
        }

        return whiteSpaceBegin.map {
            String(self.rawValue[$0...whiteSpaceEnd!])
        }
    }
}

extension Text.LineNumber {
    /// LineNumbers start at 1. But, typically `Lines` are stored in an array. This gives the equivalent value that the array of `Lines` can be indexed by.
    var arrayIndex: Int {
        self.rawValue - 1
    }

    static func +(left: Text.LineNumber, right: Text.LineNumber) -> Text.LineNumber {
        return Text.LineNumber(left.rawValue + right.rawValue)
    }

    static func +(left: Text.LineNumber, right: Int) -> Text.LineNumber {
        return Text.LineNumber(left.rawValue + right)
    }

    static func += (left: inout Text.LineNumber, right: Text.LineNumber) {
        left = left + right
    }

    static func += (left: inout Text.LineNumber, right: Int) {
        left = left + right
    }
}

extension Text.Line.Column {
    /// Columns start at 1. This gives the equivalent index by which the String's utf8 view can be indexed by.
    var zeroIndex: Int {
        self.rawValue - 1
    }
}

extension Text.Location: Comparable {
    static func == (lhs: Text.Location, rhs: Text.Location) -> Bool {
        return lhs.isEqual(rhs)
    }

    static func == (lhs: Text.Location, rhs: Text.Location?) -> Bool {
        guard let rhs = rhs else {
            return false
        }

        return lhs == rhs
    }

    static func == (lhs: Text.Location?, rhs: Text.Location) -> Bool {
        return rhs == lhs
    }

    public static func < (lhs: Text.Location, rhs: Text.Location) -> Bool {
        if lhs.lineNumber == rhs.lineNumber {
            return lhs.column < rhs.column
        } else {
            return lhs.lineNumber < rhs.lineNumber
        }
    }
}

extension Text.Location: NSTextLocation {
    public func compare(_ location: NSTextLocation) -> ComparisonResult {
        guard let location = location as? Text.Location else {
            return .orderedAscending
        }

        if self == location {
            return .orderedSame
        } else if self < location {
            return .orderedAscending
        } else {
            return .orderedDescending
        }
    }
}

fileprivate func toLines(_ string: String) -> [Text.Line] {
    var lines: [Text.Line]
    if string.isEmpty {
        lines = [Text.Line("")]
    } else {
        // String.components strip newLines from the resulting array of lines. Add them back as needed
        lines = string.components(separatedBy: .newlines).map { "\($0)\n" }
        if lines.last == "\n" || string.last != "\n" {
            // Remove last line if it only contains a new line.
            // 'night\nfor\n' should have only two lines - 'night\n' and 'for\n'. But, components returns 3 lines (last one being empty).
            // Since, we are adding \n to all the lines using map, we check if the last line contains only a newline. If so, we remove it.

            // Or,
            // Remove the trailing \n we added to the last line (as it's not on our input string)
            let _ = lines[lines.count - 1].popLast()
        }
    }

    return lines
}

