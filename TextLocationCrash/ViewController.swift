//
//  ViewController.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import Cocoa

class ViewController: NSViewController {
    var layoutManager: NSTextLayoutManager!
    var textContainer: NSTextContainer!
    var documentModel: DocumentModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let textContainer = NSTextContainer(size: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.textContainer = textContainer

        let layoutManager = NSTextLayoutManager()
        layoutManager.textContainer = textContainer
        self.layoutManager = layoutManager

        self.documentModel = DocumentModel()
        documentModel.attach(textLayoutManager: layoutManager)

        layoutManager.enumerateTextLayoutFragments(from: CustomTextLocation(column: 1), options: [.reverse, .ensuresLayout]) { fragment in
            print("\(fragment)")

            return false
        }
    }
}

