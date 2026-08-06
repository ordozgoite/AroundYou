//
//  ZoomableImageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 10/04/24.
//

import Foundation
import UIKit
import SwiftUI
 
 
// Reference: https://tinyurl.com/y2aamlqd and https://tinyurl.com/y62jzxsv
struct ZoomableImageViewRepresentable: UIViewRepresentable {
  var image: UIImage
  var onZoomScaleChanged: ((CGFloat) -> Void)?
 
  func makeUIView(context: Context) -> UIScrollView {
    // set up the UIScrollView
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator  // for viewForZooming(in:)
    scrollView.maximumZoomScale = 8
    scrollView.minimumZoomScale = 1
    scrollView.bouncesZoom = true
    scrollView.bounces = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.isScrollEnabled = false
    scrollView.backgroundColor = .clear
 
    let imageView = context.coordinator.imageView
    imageView.frame = scrollView.bounds
    scrollView.addSubview(imageView)
    return scrollView
  }
 
  func makeCoordinator() -> Coordinator {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit // by Victor Ordozgoite
    imageView.translatesAutoresizingMaskIntoConstraints = true
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.backgroundColor = .clear
    return Coordinator(imageView: imageView, onZoomScaleChanged: onZoomScaleChanged)
  }
 
  func updateUIView(_ uiView: UIScrollView, context: Context) {
    context.coordinator.onZoomScaleChanged = onZoomScaleChanged
    context.coordinator.imageView.image = self.image
  }
 
  // MARK: - Coordinator
  class Coordinator: NSObject, UIScrollViewDelegate {
    var imageView: UIImageView
    var onZoomScaleChanged: ((CGFloat) -> Void)?
   
    init(imageView: UIImageView, onZoomScaleChanged: ((CGFloat) -> Void)?) {
        self.imageView = imageView
        self.onZoomScaleChanged = onZoomScaleChanged
    }
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return imageView
    }
   
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = scrollView.zoomScale > 1.01
        onZoomScaleChanged?(scrollView.zoomScale)
        centerImage()
    }
   
    func centerImage() {
       
        // center the zoom view as it becomes smaller than the size of the screen
        let boundsSize = imageView.bounds.size
        var frameToCenter = imageView.frame
       
        // center horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width)/2
        }
        else {
            frameToCenter.origin.x = 0
        }
       
        // center vertically
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height)/2
        }
        else {
            frameToCenter.origin.y = 0
        }
       
        imageView.frame = frameToCenter
    }
  }
}
