//
//  ZoomableImageView.swift
//  feelsound
//
//  Created by 안준경 on 5/26/25.
//

import SwiftUI

// MARK: - ZoomableImageView
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let onDraw: (CGPoint) -> Void
    let onDrawingStateChanged: (Bool) -> Void
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView(image: image)
        
        setupScrollView(scrollView, context: context)
        setupImageView(imageView, context: context)
        setupConstraints(scrollView: scrollView, imageView: imageView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = uiView.subviews.first as? UIImageView {
            imageView.image = image
        }
        uiView.zoomScale = scale
        uiView.contentOffset = CGPoint(x: offset.width, y: offset.height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupScrollView(_ scrollView: UIScrollView, context: Context) {
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = scale
        scrollView.contentOffset = CGPoint(x: offset.width, y: offset.height)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    private func setupImageView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        imageView.addGestureRecognizer(panGesture)
    }
    
    private func setupConstraints(scrollView: UIScrollView, imageView: UIImageView) {
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
}

// MARK: - Coordinator
extension ZoomableImageView {
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableImageView
        var lastPoint: CGPoint?
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.scale = scrollView.zoomScale
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.offset = CGSize(width: scrollView.contentOffset.x, height: scrollView.contentOffset.y)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let imageView = gesture.view as? UIImageView,
                  let image = imageView.image else { return }
            
            let location = gesture.location(in: imageView)
            
            guard let pixelPoint = convertToPixelCoordinates(location: location, imageView: imageView, image: image)
            else { return }
            
            handleGestureState(gesture.state, at: pixelPoint)
        }
        
        private func convertToPixelCoordinates(location: CGPoint, imageView: UIImageView, image: UIImage) -> CGPoint? {
            let viewSize = imageView.bounds.size
            let imageSize = image.size
            
            let imageAspect = imageSize.width / imageSize.height
            let viewAspect = viewSize.width / viewSize.height
            
            let (displayedImageSize, imageOrigin) = calculateImageFrame(viewSize: viewSize, imageAspect: imageAspect, viewAspect: viewAspect)
            let imageFrame = CGRect(origin: imageOrigin, size: displayedImageSize)
            
            guard imageFrame.contains(location) else { return nil }
            
            let normalizedX = (location.x - imageFrame.origin.x) / imageFrame.width
            let normalizedY = (location.y - imageFrame.origin.y) / imageFrame.height
            
            return CGPoint(x: normalizedX * imageSize.width, y: normalizedY * imageSize.height)
        }
        
        private func calculateImageFrame(viewSize: CGSize, imageAspect: CGFloat, viewAspect: CGFloat) -> (CGSize, CGPoint) {
            if imageAspect > viewAspect {
                let size = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
                let origin = CGPoint(x: 0, y: (viewSize.height - size.height) / 2)
                return (size, origin)
            } else {
                let size = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
                let origin = CGPoint(x: (viewSize.width - size.width) / 2, y: 0)
                return (size, origin)
            }
        }
        
        private func handleGestureState(_ state: UIGestureRecognizer.State, at point: CGPoint) {
            switch state {
            case .began:
                parent.onDrawingStateChanged(true)
                lastPoint = point
                parent.onDraw(point)
            case .changed:
                if let lastPoint = lastPoint {
                    interpolatePoints(from: lastPoint, to: point)
                }
                lastPoint = point
            case .ended, .cancelled:
                parent.onDrawingStateChanged(false)
                lastPoint = nil
            default:
                break
            }
        }
        
        private func interpolatePoints(from startPoint: CGPoint, to endPoint: CGPoint) {
            let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
            let numberOfPoints = max(Int(distance), 10)
            
            guard numberOfPoints >= 2 else {
                parent.onDraw(endPoint)
                return
            }
            
            for i in 1...numberOfPoints {
                let ratio = CGFloat(i) / CGFloat(numberOfPoints)
                let x = startPoint.x + (endPoint.x - startPoint.x) * ratio
                let y = startPoint.y + (endPoint.y - startPoint.y) * ratio
                parent.onDraw(CGPoint(x: x, y: y))
            }
        }
    }
}
