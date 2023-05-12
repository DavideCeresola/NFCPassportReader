//
//  ResultViewController.swift
//  NFCPassportReader-Example
//
//  Created by Davide Ceresola on 11/05/23.
//

import NFCPassportReader
import UIKit

class ResultViewController: UIViewController {
    
    private lazy var textView: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isEditable = false
        return view
    }()
    
    private let result: NFCData
    
    init(result: NFCData) {
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
        
        textView.text = buildText()
    }
    
    private func buildText() -> String {
        
        let mirror = Mirror(reflecting: result)
        let mirrored = mirror.children.map { child in
            return "\(child.label ?? "Unknown label"): \(child.value)"
        }
        
        let computed = [
            "DateOfBirth:" : result.dateOfBirth,
            "IssuingDate:": result.issuingDate,
            "ExpirationDate:": result.expirationDate,
        ].compactMapValues { $0 }
            .map {
                "\($0.key) \($0.value)"
            }
        
        return (mirrored + computed).joined(separator: "\n")
    }
    
}
