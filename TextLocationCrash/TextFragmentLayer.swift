//
//  TextFragmentLayer.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 31/12/23.
//

import AppKit
import Logging

class TextFragmentLayer: CALayer {
    var logger = {
        var logger = Logger(label: "in.roguemonkey.TextLocationCrash.TextFragmentLayer")
        logger.logLevel = .error

        return logger
    }()

    var textLayoutFragment: NSTextLayoutFragment!
    var padding: CGFloat = 5

    init(layoutFragment: NSTextLayoutFragment) {
        self.textLayoutFragment = layoutFragment
        super.init()
        updateGeometry()
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default animations
        return NSNull()
    }

    func updateGeometry() {
        bounds = textLayoutFragment.renderingSurfaceBounds
        // The (0, 0) point in layer space should be the anchor point.
        anchorPoint = CGPoint(x: -bounds.origin.x / bounds.size.width, y: -bounds.origin.y / bounds.size.height)
        position = textLayoutFragment.layoutFragmentFrame.origin
        var newBounds = bounds
        newBounds.origin.x += position.x
        bounds = newBounds
        position.x += padding
    }

    override func draw(in ctx: CGContext) {
        logger.debug("drawing frame with bounds: \(bounds)")
        textLayoutFragment.draw(at: .zero, in: ctx)
    }

}
