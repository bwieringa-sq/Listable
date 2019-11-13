//
//  CollectionViewBasicDemoViewController.swift
//  Listable-DemoApp
//
//  Created by Kyle Van Essen on 7/9/19.
//

import UIKit

import Listable


final class CollectionViewBasicDemoViewController : UIViewController
{
    var rows : [[DemoElement]] = [
        [
            DemoElement(text: "Nam sit amet imperdiet odio. Duis sed risus aliquet, finibus ex in, maximus diam. Mauris dapibus cursus rhoncus. Fusce faucibus velit at leo vestibulum, a pharetra dui interdum."),
            DemoElement(text: "Row 2"),
        ],
        [
            DemoElement(text: "Row 1"),
            DemoElement(text: "Row 2"),
            DemoElement(text: "Row 3"),
        ],
        ]
    
    let listView = ListView()
    
    override func loadView()
    {
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addItem)),
            UIBarButtonItem(title: "Remove", style: .plain, target: self, action: #selector(removeItem))
        ]
        
        self.view = listView
        
        self.updateTable(animated: false)
    }
    
    var itemAppearance : DemoElement.Appearance {
        return DemoElement.Appearance { label in
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 16.0, weight: .regular)
        }
    }
    
    var headerAppearance : HeaderElement.Appearance {
        return HeaderElement.Appearance { label in
            label.font = .systemFont(ofSize: 18.0, weight: .bold)
        }
    }
    
    var footerAppearance : FooterElement.Appearance {
        return FooterElement.Appearance { label in
            label.textColor = .darkGray
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 14.0, weight: .regular)
            label.textAlignment = .center
        }
    }
    
    func updateTable(animated : Bool)
    {
        listView.appearance = defaultAppearance
        
        listView.setContent(animated: animated) { list in
            
            list += self.rows.map { sectionRows in
                Section(identifier: "Demo Section") { section in
                    
                    section.columns = .init(count: 2, spacing: 10.0)
                     
                    section.header = HeaderFooter(
                        with: HeaderElement(title: "Section Header"),
                        appearance: self.headerAppearance
                    )
                    
                    section.footer = HeaderFooter(
                        with: FooterElement(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi non luctus sem, eu consectetur ipsum. Curabitur malesuada cursus ante."),
                        appearance: self.footerAppearance,
                        sizing: .thatFits(.noConstraint)
                    )
                    
                    section += sectionRows.map { row in
                        Item(
                            with: row,
                            appearance: self.itemAppearance,
                            sizing: .thatFits(.atLeast(.default))
                        )
                    }
                }
            }
        }
    }
    
    @objc func addItem()
    {
        self.rows[0].insert(DemoElement(text: Date().description), at: 0)
        self.rows[1].insert(DemoElement(text: Date().description), at: 0)
        
        self.updateTable(animated: true)
    }
    
    @objc func removeItem()
    {
        if self.rows[0].isEmpty == false {
            self.rows[0].removeLast()
        }
        
        if self.rows[1].isEmpty == false {
            self.rows[1].removeLast()
        }
        
        self.updateTable(animated: true)
    }
}


struct HeaderElement : HeaderFooterElement, Equatable
{
    var title : String
    
    // HeaderFooterElement
    
    typealias Appearance = HeaderAppearance<UILabel>
    
    func apply(to views: HeaderFooterElementView<UILabel, UIView>, reason: ApplyReason)
    {
        views.content.text = self.title
    }
}

struct FooterElement : HeaderFooterElement, Equatable
{
    var text : String
    
    // HeaderFooterElement
    
    typealias Appearance = FooterAppearance<UILabel>
    
    func apply(to views: HeaderFooterElementView<UILabel, UIView>, reason: ApplyReason)
    {
        views.content.text = self.text
    }
}

struct DemoElement : ItemElement, Equatable
{
    var text : String

    // ItemElement
    
    typealias Appearance = ItemAppearance<UILabel>
    
    var identifier: Identifier<DemoElement> {
        return .init(self.text)
    }
    
    func apply(to view: Appearance.View, with state : ItemState, reason: ApplyReason)
    {
        view.content.text = self.text
    }
}
