//
//  TextView.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 31/12/23.
//

import AppKit
import Logging

class TextView: NSView, CALayerDelegate {
    var logger = {
        var logger = Logger(label: "in.roguemonkey.TextLocationCrash.TextView")
        logger.logLevel = .error

        return logger
    }()

    override var isFlipped: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }


    internal var backingScaleFactor: CGFloat { window?.backingScaleFactor ?? 1 }
    internal var contentLayer: CALayer!
    var layoutManager: NSTextLayoutManager!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        logger.debug("layer.delegate: \(String(describing: layer?.delegate))")

        let contentLayer = CALayer()
        self.contentLayer = contentLayer
        layer?.addSublayer(contentLayer)

        translatesAutoresizingMaskIntoConstraints = false
    }

    override func prepareContent(in rect: NSRect) {
        layer!.setNeedsLayout()
        super.prepareContent(in: rect)
    }

    func resetContentLayer() {
        contentLayer.sublayers = nil
    }


    func add(fragmentLayer layer: TextFragmentLayer) {
        logger.debug("Adding fragment layer: \(layer.textLayoutFragment.layoutFragmentFrame)")
        logger.debug("fragment frame: \(layer.frame) bounds: \(layer.bounds)")
        layer.contentsScale = backingScaleFactor
        self.contentLayer?.addSublayer(layer)
    }

    // Scroll view support.
    private var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else { return nil }
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }

    private func adjustViewportOffsetIfNeeded() {
        let viewportLayoutController = layoutManager.textViewportLayoutController
        let contentOffset = scrollView!.contentView.bounds.minY
        if contentOffset < scrollView!.contentView.bounds.height &&
            viewportLayoutController.viewportRange!.location.compare(layoutManager!.documentRange.location) == .orderedDescending {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLayoutController.viewportRange!.location.compare(layoutManager!.documentRange.location) == .orderedSame {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }


    private func adjustViewportOffset() {
        let viewportLayoutController = layoutManager!.textViewportLayoutController
        var layoutYPoint: CGFloat = 0
        layoutManager!.enumerateTextLayoutFragments(from: viewportLayoutController.viewportRange!.location,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
            return true
        }
        if layoutYPoint != 0 {
            let adjustmentDelta = bounds.minY - layoutYPoint
            viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
            scroll(CGPoint(x: scrollView!.contentView.bounds.minX, y: scrollView!.contentView.bounds.minY + adjustmentDelta))
        }
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        let clipView = scrollView?.contentView
        if clipView != nil {
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: clipView)
        }

        super.viewWillMove(toSuperview: newSuperview)
    }

    private var boundsDidChangeObserver: Any? = nil

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()

        let clipView = scrollView?.contentView
        if clipView != nil {
            boundsDidChangeObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                                   object: clipView,
                                                   queue: nil) { [weak self] notification in
                self!.layer?.setNeedsLayout()
            }
        }
    }
}
