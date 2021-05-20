//
//  IMGLYStickersEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

let StickersCollectionViewCellSize = CGSize(width: 90, height: 90)
let StickersCollectionViewCellReuseIdentifier = "StickersCollectionViewCell"

extension Notification.Name {
    public static let didImageSelect = Notification.Name(rawValue: "didImageSelectNotify")
}

open class IMGLYStickersEditorViewController: IMGLYSubEditorViewController {

    // MARK: - Properties
    let circleOverlyView = IMGLYCircleLayerView()
    open var stickersDataSource = IMGLYStickersDataSource()
    open fileprivate(set) lazy var stickersClipView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
        }()
    fileprivate var isViewDidAppear: Bool = false
    fileprivate var draggedView: UIView?
    fileprivate var tempStickerCopy = [CIFilter]()
    
    fileprivate var cropRect = CGRect.zero
    fileprivate var cropRectLeftBound = CGFloat(0)
    fileprivate var cropRectRightBound = CGFloat(0)
    fileprivate var cropRectTopBound = CGFloat(0)
    fileprivate var cropRectBottomBound = CGFloat(0)

    
    // MARK: - SubEditorViewController
    
    open override func tappedDone(_ sender: UIBarButtonItem?) {
        var addedStickers = false
        
        for view in self.view.subviews {
            if let view = view as? UIImageView {
                if let image = view.image {
                    let stickerFilter = IMGLYInstanceFactory.stickerFilter()
                    stickerFilter.sticker = image
                    let center = CGPoint(x: (view.center.x - stickersClipView.frame.origin.x) / stickersClipView.frame.size.width,
                                         y: (view.center.y - stickersClipView.frame.origin.y) / stickersClipView.frame.size.height)
                    
                    var size = initialSizeForStickerImage(image)
                    size.width = size.width / self.circleOverlyView.bounds.size.width
                    size.height = size.height / self.circleOverlyView.bounds.size.height
                    stickerFilter.center = center
                    stickerFilter.scale = size.width
                    stickerFilter.transform = view.transform
                    fixedFilterStack.stickerFilters.append(stickerFilter)
                    addedStickers = true
                }
            }
        }
        
        if addedStickers {
            self.fixedFilterStack.orientationCropFilter.cropRect = normalizedCropRect()
            updatePreviewImageWithCompletion {
                self.stickersClipView.removeFromSuperview()
                super.tappedDone(sender)
            }
        } else {
            super.tappedDone(sender)
        }
    }
    
    fileprivate func reCalculateCropRectBounds() {
        let width = self.circleOverlyView.frame.size.width
        let height = self.circleOverlyView.frame.size.height
        cropRectLeftBound = (width - previewImageView.visibleImageFrame.size.width) / 2.0
        cropRectRightBound = width - cropRectLeftBound
        cropRectTopBound = (height - previewImageView.visibleImageFrame.size.height) / 2.0
        cropRectBottomBound = height - cropRectTopBound
    }

    fileprivate func normalizedCropRect() -> CGRect {
        
        if self.previewImageView.minimumZoomScale == self.previewImageView.zoomScale {
            setCropRectForSelectionRatio()
            reCalculateCropRectBounds()
            let boundWidth = cropRectRightBound - cropRectLeftBound
            let boundHeight = cropRectBottomBound - cropRectTopBound
            let x = (self.cropRect.origin.x - cropRectLeftBound) / boundWidth
            let y = (self.cropRect.origin.y - cropRectTopBound) / boundHeight
            let cropRect = CGRect(x: x, y: y, width: self.cropRect.size.width / boundWidth, height: self.cropRect.size.height / boundHeight)
            return cropRect
        }
        else {
            let scale: CGFloat = 1/previewImageView.zoomScale

            /*let x: CGFloat = previewImageView.contentOffset.x * scale
            let y: CGFloat = previewImageView.contentOffset.y * scale
            let width: CGFloat = previewImageView.frame.size.width * scale
            let height: CGFloat = previewImageView.frame.size.height * scale*/
            
            let x: CGFloat = (previewImageView.contentOffset.x + self.circleOverlyView.circleBounds.origin.x) * scale
            let y: CGFloat = (previewImageView.contentOffset.y + self.circleOverlyView.circleBounds.origin.y) * scale
            let width: CGFloat = self.circleOverlyView.circleBounds.size.width * scale
            let height: CGFloat = self.circleOverlyView.circleBounds.size.height * scale
            
            let posX = x / self.previewImageView.image!.size.width
            let posY = y / self.previewImageView.image!.size.height
            let posWidth = width / self.previewImageView.image!.size.width
            let posHeight = height / self.previewImageView.image!.size.height
            
            let cropFrame = CGRect(x: posX, y: posY, width: posWidth, height: posHeight)
            return cropFrame
        }
    }
    
    fileprivate func setCropRectForSelectionRatio() {
        let size = CGSize(width: cropRectRightBound - cropRectLeftBound,
            height: cropRectBottomBound - cropRectTopBound)
        var rectWidth = size.width
        var rectHeight = rectWidth
        if size.width > size.height {
            rectHeight = size.height
            rectWidth = rectHeight
        }
        rectHeight /= 1
        
        let sizeDeltaX = (size.width - rectWidth) / 2.0
        let sizeDeltaY = (size.height - rectHeight) / 2.0
        
        self.cropRect = CGRect(
            x: cropRectLeftBound  + sizeDeltaX,
            y: cropRectTopBound + sizeDeltaY,
            width: rectWidth,
            height: rectHeight)
        //print("crop Rect ==>", self.cropRect, self.cutterView.frame)
    }
    
    // MARK: - Helpers
    
    @objc func notificationReceived(_ notification: Notification) {
        self.updating = false
        guard let img = notification.userInfo?["image"] as? UIImage else {
            navigationController?.popViewController(animated: true)
            return
        }
        let imageView = UIImageView(image: img)
        imageView.isUserInteractionEnabled = true
        imageView.frame.size = initialSizeForStickerImage(img)
        imageView.center = CGPoint(x: self.circleOverlyView.circleBounds.midX, y: self.circleOverlyView.circleBounds.midY)
        self.view.addSubview(imageView)
        imageView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            imageView.transform = CGAffineTransform.identity
            }, completion: nil)
        self.view.bringSubviewToFront(self.circleOverlyView)
    }
    
    fileprivate func initialSizeForStickerImage(_ image: UIImage) -> CGSize {
        let initialMaxStickerSize = stickersClipView.bounds.width * 0.3
        let widthRatio = initialMaxStickerSize / image.size.width
        let heightRatio = initialMaxStickerSize / image.size.height
        let scale = min(widthRatio, heightRatio)
        
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }
    
    open override var enableZoomingInPreviewImage: Bool {
        return true
    }
    
    // MARK: - UIViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        navigationItem.title = NSLocalizedString("stickers-editor.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        //configureStickersCollectionView()
        
        configureStickersClipView()
        configureCropView()
        configureGestureRecognizers()
        backupStickers()
        if self.fixedFilterStack.stickerFilters.count == 0 {
            self.delegate?.openPhotoCollection()
            self.updating = true
        }
        fixedFilterStack.stickerFilters.removeAll()
        
        rerenderPreviewWithoutStickers()
        
        let cropRect = fixedFilterStack.orientationCropFilter.cropRect
        if cropRect.origin.x != 0 || cropRect.origin.y != 0 ||
            cropRect.size.width != 1.0 || cropRect.size.height != 1.0 {
            updatePreviewImageWithCompletion {
                self.lowResolutionImage = self.previewImageView.image
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                self.reCalculateCropRectBounds()
            }
        } else {
            updatePreviewImageWithoutCropWithCompletion {
                self.reCalculateCropRectBounds()
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.isViewDidAppear == false else {
            return
        }
        
        self.isViewDidAppear = true
        self.setCropRectForSelectionRatio()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didImageSelect, object: nil)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: .didImageSelect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: .didImageSelect, object: nil)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.isViewDidAppear == false else {
            return
        }
        stickersClipView.frame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        circleOverlyView.frame = self.previewImageView.frame
        circleOverlyView.circleFrame = view.convert(previewImageView.visibleImageFrame, from: previewImageView)
        reCalculateCropRectBounds()
    }
        
    fileprivate func updatePreviewImageWithoutCropWithCompletion(_ completionHandler: IMGLYPreviewImageGenerationCompletionBlock?) {
        let oldCropRect = fixedFilterStack.orientationCropFilter.cropRect
        fixedFilterStack.orientationCropFilter.cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        updatePreviewImageWithCompletion { () -> (Void) in
            self.fixedFilterStack.orientationCropFilter.cropRect = oldCropRect
            completionHandler?()
        }
    }
    
    // MARK: - Configuration
    
    fileprivate func configureCropView() {
        view.addSubview(circleOverlyView)
    }
    
    fileprivate func configureStickersCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = StickersCollectionViewCellSize
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = stickersDataSource
        collectionView.delegate = self
        collectionView.register(IMGLYStickerCollectionViewCell.self, forCellWithReuseIdentifier: StickersCollectionViewCellReuseIdentifier)
        
        let views = [ "collectionView" : collectionView ]
        bottomContainerView.addSubview(collectionView)
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[collectionView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: [], metrics: nil, views: views))
    }
    
    fileprivate func configureStickersClipView() {
        stickersClipView.isUserInteractionEnabled = false
        view.addSubview(stickersClipView)
    }
    
    fileprivate func configureGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.panned(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.pinched(_:)))
        pinchGestureRecognizer.delegate = self
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(IMGLYStickersEditorViewController.rotated(_:)))
        rotationGestureRecognizer.delegate = self
        view.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    // MARK: - Gesture Handling
    
    @objc fileprivate func panned(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self.view)
        let translation = recognizer.translation(in: self.view)
        
        switch recognizer.state {
        case .began:
            draggedView = view.hitTest(location, with: nil) as? UIImageView
        case .changed:
            if let draggedView = draggedView {
                guard  (draggedView.center.y + translation.y < self.circleOverlyView.frame.maxY && draggedView.center.y + translation.y > self.circleOverlyView.frame.minY) && (draggedView.center.x + translation.x > self.circleOverlyView.frame.minX && draggedView.center.x + translation.x < self.circleOverlyView.frame.maxX) else {
                    return
                }
                draggedView.center = CGPoint(x: draggedView.center.x + translation.x, y: draggedView.center.y + translation.y)
            }
            
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        case .cancelled, .ended:
            draggedView = nil
        default:
            break
        }
    }
    
    @objc fileprivate func pinched(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.numberOfTouches == 2 {
            let point1 = recognizer.location(ofTouch: 0, in: self.view)
            let point2 = recognizer.location(ofTouch: 1, in: self.view)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let scale = recognizer.scale
            
            switch recognizer.state {
            case .began:
                if draggedView == nil {
                    draggedView = self.view.hitTest(midpoint, with: nil) as? UIImageView
                }
            case .changed:
                if let draggedView = draggedView {
                    draggedView.transform = draggedView.transform.scaledBy(x: scale, y: scale)
                }
                
                recognizer.scale = 1
            case .cancelled, .ended:
                draggedView = nil
            default:
                break
            }
        }
    }
    
    @objc fileprivate func rotated(_ recognizer: UIRotationGestureRecognizer) {
        if recognizer.numberOfTouches == 2 {
            let point1 = recognizer.location(ofTouch: 0, in: self.view)
            let point2 = recognizer.location(ofTouch: 1, in: self.view)
            let midpoint = CGPoint(x:(point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            let rotation = recognizer.rotation
            
            switch recognizer.state {
            case .began:
                if draggedView == nil {
                    draggedView = self.view.hitTest(midpoint, with: nil) as? UIImageView
                }
            case .changed:
                if let draggedView = draggedView {
                    draggedView.transform = draggedView.transform.rotated(by: rotation)
                }
                
                recognizer.rotation = 0
            case .cancelled, .ended:
                draggedView = nil
            default:
                break
            }
        }
    }
    
    
    // MARK: - sticker object restore
    
    fileprivate func rerenderPreviewWithoutStickers() {
        updatePreviewImageWithCompletion { () -> (Void) in
            self.addStickerImagesFromStickerFilters(self.tempStickerCopy)
        }
    }
    
    fileprivate func addStickerImagesFromStickerFilters(_ stickerFilters: [CIFilter]) {
        for element in stickerFilters {
            guard let stickerFilter = element as? IMGLYStickerFilter else {
                return
            }
            
            let imageView = UIImageView(image: stickerFilter.sticker)
            imageView.isUserInteractionEnabled = true
            
            let size = stickerFilter.absolutStickerSizeForImageSize(stickersClipView.bounds.size)
            imageView.frame.size = size
            
            let center = CGPoint(x: stickerFilter.center.x * self.circleOverlyView.frame.size.width,
                                 y: stickerFilter.center.y * circleOverlyView.frame.size.height)
            imageView.center = center
            imageView.transform = stickerFilter.transform
            view.addSubview(imageView)
            self.view.bringSubviewToFront(self.circleOverlyView)
        }
    }
    
    fileprivate func backupStickers() {
        tempStickerCopy = fixedFilterStack.stickerFilters
    }
}

extension IMGLYStickersEditorViewController: UICollectionViewDelegate {
    // add selected sticker
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sticker = stickersDataSource.stickers[indexPath.row]
        let imageView = UIImageView(image: sticker.image)
        imageView.isUserInteractionEnabled = true
        imageView.frame.size = initialSizeForStickerImage(sticker.image)
        imageView.center = CGPoint(x: self.circleOverlyView.frame.midX, y: self.circleOverlyView.frame.midY)
        view.addSubview(imageView)
        self.view.bringSubviewToFront(self.circleOverlyView)
        imageView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            imageView.transform = CGAffineTransform.identity
            }, completion: nil)
    }
}

extension IMGLYStickersEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) || (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
                        
            return true
        }
        
        return false
    }
}
