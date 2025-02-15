//
//  ViewController.swift
//  NFCPassportReader-Example
//
//  Created by Davide Ceresola on 11/05/23.
//

import NFCPassportReader
import UIKit

class ViewController: UIViewController {
    
    private lazy var contentView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 20.0
        view.alignment = .center
        view.addArrangedSubview(tdToggle)
        view.addArrangedSubview(mrzTextField)
        view.addArrangedSubview(startButton)
        return view
    }()
    
    private lazy var tdToggle: UISegmentedControl = {
        let view = UISegmentedControl()
        view.insertSegment(withTitle: "TD3", at: 0, animated: false)
        view.insertSegment(withTitle: "TD1", at: 0, animated: false)
        return view
    }()
    
    private lazy var mrzTextField: UITextField = {
        let textField = UITextField()
        textField.isEnabled = false
        return textField
    }()
    
    private lazy var startButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Start NFC", for: .normal)
        return view
    }()
    
    private let mrzText = ""
    
    private var scanner: NFCPassportReader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mrzTextField.text = mrzText
        
        startButton.addTarget(self, action: #selector(startAction), for: .touchUpInside)
        
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.topAnchor),
        ])
    }

    @objc private func startAction() {
        
        let text = mrzText
        
        let mrzData: MRZData
        
        switch tdToggle.selectedSegmentIndex {
        case 0:
            guard let data = firstValidMRZTD1(into: text) else { return }
            mrzData = data.parsedData
        case 1:
            guard let data = firstValidMRZTD3(into: text) else { return }
            mrzData = data.parsedData
        default:
            return
        }
        
        scanner = .init(mrzData: mrzData)
        scanner!.delegate = self
        scanner!.start(with: "DEBUGGING!")
        
    }
    
    private func firstValidMRZTD1(into scanned: String) -> MRZTD1? {

        for index in scanned.indices {

            let mrz = MRZTD1(scan: String(scanned[index...]))

            let isValid = mrz.isValid()
            print("isValid:", isValid)
            if isValid < 0.95 {
                continue
            }

            return mrz

        }

        return nil

    }
    
    private func firstValidMRZTD3(into scanned: String) -> MRZTD3? {

        for index in scanned.indices {

            let mrz = MRZTD3(scan: String(scanned[index...]))

            let isValid = mrz.isValid()
            print("isValid:", isValid)
            if isValid < 0.95 {
                continue
            }

            return mrz

        }

        return nil

    }

}

extension ViewController: NFCPassportReaderDelegate {
    
    func reader(didSuccededWith data: NFCData) {
        
        DispatchQueue.main.async {
            guard let navigationController = self.navigationController else { return }
            let controller = ResultViewController(result: data)
            navigationController.pushViewController(controller, animated: true)
        }
        
    }
    
    func reader(didFailedWith error: NFCError) {
        print("Failed:", error)
    }
    
    func readerMessage(for progress: Double) -> String? {
        return String(progress)
    }
    
    func readerFailedMessage() -> String? {
        return "Failed"
    }
    
}

