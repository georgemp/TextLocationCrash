//
//  Document.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import AppKit

class CustomTextLocation: NSObject {
    var column: Int = 1 // Not zero indexed.

    init(column: Int) {
        self.column = column
    }

    override public var description: String {
        "\(column)"
    }
}

extension CustomTextLocation: NSTextLocation {
    func compare(_ location: NSTextLocation) -> ComparisonResult {
        guard let location = location as? CustomTextLocation else {
            fatalError("Expected Document.Location")
        }

        if column < location.column {
            return .orderedAscending
        } else if column == location.column {
            return .orderedSame
        } else {
            return .orderedDescending
        }
    }
}

