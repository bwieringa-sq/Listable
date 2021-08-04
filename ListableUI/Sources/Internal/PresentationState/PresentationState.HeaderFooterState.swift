//
//  PresentationState.HeaderFooterState.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 5/22/20.
//

import Foundation


protocol AnyPresentationHeaderFooterState : AnyObject
{
    var anyModel : AnyHeaderFooter { get }
        
    func dequeueAndPrepareReusableHeaderFooterView(
        in cache : ReusableViewCache,
        frame : CGRect,
        environment : ListEnvironment
    ) -> SupplementaryContainerViewContentView
    
    func enqueueReusableHeaderFooterView(_ view : UIView, in cache : ReusableViewCache)
    
    func applyTo(
        view : UIView,
        for reason : ApplyReason,
        with info : ApplyHeaderFooterContentInfo
    )

    func setNew(headerFooter anyHeaderFooter : AnyHeaderFooter)
    
    func resetCachedSizes()
    func size(
        for info : Sizing.MeasureInfo,
        cache : ReusableViewCache,
        environment : ListEnvironment
    ) -> CGSize
}


extension PresentationState
{
    final class HeaderFooterViewStatePair
    {
        var state : AnyPresentationHeaderFooterState? {
            didSet {
                guard oldValue !== self.state else {
                    return
                }
                
                guard let container = self.visibleContainer else {
                    return
                }
                
                container.headerFooter = self.state
            }
        }
        
        private(set) var visibleContainer : SupplementaryContainerView?
        
        func willDisplay(view : SupplementaryContainerView)
        {
            self.visibleContainer = view
        }
        
        func didEndDisplay()
        {
            self.visibleContainer = nil
        }
        
        func applyToVisibleView(with environment : ListEnvironment)
        {
            guard let view = visibleContainer?.content, let state = self.state else {
                return
            }
            
            state.applyTo(
                view: view,
                for: .wasUpdated,
                with: .init(environment: environment)
            )
        }
    }
    
    
    final class HeaderFooterState<Content:HeaderFooterContent> : AnyPresentationHeaderFooterState
    {
        var model : HeaderFooter<Content>
        
        let performsContentCallbacks : Bool
                
        init(_ model : HeaderFooter<Content>, performsContentCallbacks : Bool)
        {
            self.model = model
            self.performsContentCallbacks = performsContentCallbacks
        }
        
        // MARK: AnyPresentationHeaderFooterState
        
        var anyModel: AnyHeaderFooter {
            return self.model
        }
                
        func dequeueAndPrepareReusableHeaderFooterView(
            in cache : ReusableViewCache,
            frame : CGRect,
            environment : ListEnvironment
        ) -> SupplementaryContainerViewContentView
        {
            let view = cache.pop(with: self.model.reuseIdentifier) {
                HeaderFooterContentView<Content>(frame: frame)
            }
            
            self.applyTo(
                view: view,
                for: .willDisplay,
                with: .init(environment: environment)
            )
            
            view.onPrepareForReuse = { [weak self] in
                self?.model.content.prepareViewsForReuse(.init(view: view))
            }
            
            return view
        }
        
        func enqueueReusableHeaderFooterView(_ view : UIView, in cache : ReusableViewCache)
        {
            cache.push(view, with: self.model.reuseIdentifier)
        }
        
        func applyTo(
            view : UIView,
            for reason : ApplyReason,
            with info : ApplyHeaderFooterContentInfo
        ) {
            let view = view as! HeaderFooterContentView<Content>
            
            let views = HeaderFooterContentViews(view: view)
            
            view.onTap = self.model.onTap.map { onTap in { [weak self] in
                    guard let self = self else { return }
                    
                    onTap(self.model.content)
                }
            }
            
            self.model.content.apply(to: views, for: reason, with: info)
        }
        
        func setNew(headerFooter anyHeaderFooter: AnyHeaderFooter)
        {
            let oldModel = self.model
            
            self.model = anyHeaderFooter as! HeaderFooter<Content>
            
            let isEquivalent = self.model.anyIsEquivalent(to: oldModel)
            
            if isEquivalent == false {
                self.resetCachedSizes()
            }
        }
        
        private var cachedSizes : [SizeKey:CGSize] = [:]
        
        func resetCachedSizes()
        {
            self.cachedSizes.removeAll()
        }
        
        func size(
            for info : Sizing.MeasureInfo,
            cache : ReusableViewCache,
            environment : ListEnvironment
        ) -> CGSize
        {
            guard info.sizeConstraint.isEmpty == false else {
                return .zero
            }
            
            let key = SizeKey(
                width: info.sizeConstraint.width,
                height: info.sizeConstraint.height,
                layoutDirection: info.direction,
                sizing: self.model.sizing
            )
            
            if let size = self.cachedSizes[key] {
                return size
            } else {
                SignpostLogger.log(.begin, log: .updateContent, name: "Measure HeaderFooter", for: self.model)
                
                let size : CGSize = cache.use(
                    with: self.model.reuseIdentifier,
                    create: {
                        return HeaderFooterContentView<Content>(frame: .zero)
                }, { view in
                    self.model.content.apply(
                        to: HeaderFooterContentViews(view: view),
                        for: .willDisplay,
                        with: .init(environment: environment)
                    )
                    
                    return self.model.sizing.measure(with: view, info: info)
                })
                
                self.cachedSizes[key] = size
                
                SignpostLogger.log(.end, log: .updateContent, name: "Measure HeaderFooter", for: self.model)
                
                return size
            }
        }
    }
}
