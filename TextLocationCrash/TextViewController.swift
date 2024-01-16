//
//  ViewController.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import Cocoa
import Logging

class TextViewController: NSViewController, CALayerDelegate {
    @IBOutlet var textView: TextView!

    var logger = Logger(label: "in.roguemonkey.TextLocationCrash.ViewController")
    var layoutManager: NSTextLayoutManager!
    var textContainer: NSTextContainer!
    var documentModel: DocumentModel!

    override func viewDidLoad() {
        logger.debug("viewDidLoad")
        logger.logLevel = .error
        
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        logger.debug("view.frame: \(view.frame)")

        let layoutManager = NSTextLayoutManager()
        self.layoutManager = layoutManager
        textView.layoutManager = layoutManager

        self.documentModel = DocumentModel()
        documentModel.attach(textLayoutManager: layoutManager)

        // Do any additional setup after loading the view.
        let textContainer = NSTextContainer(size: NSSize(width: 400, height: 280))
        layoutManager.textContainer = textContainer
        self.textContainer = textContainer

        layoutManager.textViewportLayoutController.delegate = self
        textView.layer?.delegate = self

        layoutManager.textSelections = [NSTextSelection(range: NSTextRange(location: documentModel.currentEndLocation, end: documentModel.currentEndLocation)!, affinity: .downstream, granularity: .character)]

        layoutManager.textContentManager?.performEditingTransaction {
            documentModel.stepLocation()
        }
        textView.layer?.setNeedsLayout()
    }
}

extension TextViewController: NSTextViewportLayoutControllerDelegate {
    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let overdrawRect = view.preparedContentRect
        let visibleRect = view.visibleRect
        var minY: CGFloat = 0
        var maxY: CGFloat = 0
        if overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minY = min(overdrawRect.minY, max(visibleRect.minY, 0))
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // We use visible rect directly if preparedContentRect does not intersect.
            // This can happen if overdraw has not caught up with scrolling yet, such as before the first layout.
            minY = visibleRect.minY
            maxY = visibleRect.maxY
        }

        let bounds = view.bounds
        let viewportBounds = CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)

        logger.debug("viewport bounds: \(viewportBounds)")
        return viewportBounds
    }

    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        // Notes: This is needed to avoid stacking of layers on typing
        textView.resetContentLayer()

        // The animation is done to allow moving of paragraphs/blocks of text when their position changes.
        // For example, when resizing the window some text might move to the next or previous line. This will change the position of paragraph starts.
        logger.debug("textViewportLayoutControllerWillLayout")
        CATransaction.begin()
    }

    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        CATransaction.commit()
        logger.debug("textViewportLayoutControllerDidLayout")
        logger.debug("")

        // TODO: check if we need to handle scroll to current insertion/selection here
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        logger.debug("configureRenderingSurfaceFor \(textLayoutFragment)")
        let layer = TextFragmentLayer(layoutFragment: textLayoutFragment)
        textView.add(fragmentLayer: layer)
    }

    func layoutSublayers(of layer: CALayer) {
        layoutManager?.textViewportLayoutController.layoutViewport()

        DispatchQueue.main.async {[weak self] in
            guard let weakSelf = self else {
                return
            }

            guard let layoutManager = weakSelf.layoutManager,
                  let documentModel = weakSelf.documentModel,
                  let textView = weakSelf.textView else {
                return
            }

            if documentModel.currentEndLocation < documentModel.fullText.range.upperBound  {
                layoutManager.textContentManager?.performEditingTransaction {
                    documentModel.stepLocation()
                }

                textView.layer?.setNeedsLayout()
                layoutManager.textSelections = [NSTextSelection(range: NSTextRange(location: documentModel.currentEndLocation, end: documentModel.currentEndLocation)!, affinity: .downstream, granularity: .character)]
            }
        }
    }
}
