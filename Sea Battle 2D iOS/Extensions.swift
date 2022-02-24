//
//  Extensions.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 22.02.2022.
//  Copyright © 2022 Vlad Nechyporenko. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension UIViewController {
    /*! @fn showMessagePrompt
     @brief Displays an alert with an 'OK' button and a message.
     @param message The message to display.
     */
    func showMessagePrompt(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: false, completion: nil)
    }
    
    /*! @fn showTextInputPromptWithMessage
     @brief Shows a prompt with a text field and 'OK'/'Cancel' buttons.
     @param message The message to display.
     @param completion A block to call when the user taps 'OK' or 'Cancel'.
     */
    func showTextInputPrompt(withMessage message: String,
                             completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let text = weakPrompt?.textFields?.first?.text else { return }
            completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
    }
    
    /*! @fn showSpinner
     @brief Shows the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func showSpinner(_ completion: (() -> Void)?) {
        let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                                preferredStyle: .alert)
        SaveAlertHandle.set(alertController)
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.color = UIColor(ciColor: .black)
        spinner.center = CGPoint(x: alertController.view.frame.midX,
                                 y: alertController.view.frame.midY)
        spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                    .flexibleLeftMargin, .flexibleRightMargin]
        spinner.startAnimating()
        alertController.view.addSubview(spinner)
        present(alertController, animated: true, completion: completion)
    }
    
    /*! @fn hideSpinner
     @brief Hides the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func hideSpinner(_ completion: (() -> Void)?) {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            controller.dismiss(animated: true, completion: completion)
        }
    }
}

private class SaveAlertHandle {
    static var alertHandle: UIAlertController?
    
    class func set(_ handle: UIAlertController) {
        alertHandle = handle
    }
    
    class func clear() {
        alertHandle = nil
    }
    
    class func get() -> UIAlertController? {
        return alertHandle
    }
}

extension UIViewController {
    func firebaseAction(itemID: String, itemName: String) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: itemID,
            AnalyticsParameterItemName: itemName,
            AnalyticsParameterContentType: "cont",
        ])
    }
}

extension NSLayoutConstraint {
    
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" 
    }
}


extension UIButton {
    @IBInspectable var adjustFontSizeToWidth: Bool {
        get {
            return self.titleLabel!.adjustsFontSizeToFitWidth
        }
        set {
            self.titleLabel?.numberOfLines = 1
            self.titleLabel?.adjustsFontSizeToFitWidth = newValue;
            self.titleLabel?.lineBreakMode = .byClipping;
            self.titleLabel?.baselineAdjustment = .alignCenters
        }
    }
}

@IBDesignable
class DesignableView: UIView {
}

@IBDesignable
class DesignableButton: UIButton {
}

@IBDesignable
class DesignableLabel: UILabel {
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}

extension UIViewController {
    
    enum FontSizeStatus {
        case verySmall
        case small
        case medium
        case big
        case veryBig
    }
    
    func adjustFont(for button: UIButton, using fontSizeStatus: FontSizeStatus) {
        button.titleLabel?.font = .systemFont(ofSize: min(self.view.frame.height,self.view.frame.width) / getFontSizeCGFloatFactor(from: fontSizeStatus))
        button.layer.borderWidth = 2
        if self.traitCollection.userInterfaceStyle == .dark {
            button.layer.borderColor = UIColor.white.cgColor
        }
        else {
            button.layer.borderColor = UIColor.black.cgColor
        }
    }
    func adjustFont(for label: UILabel, using fontSizeStatus: FontSizeStatus) {
        label.font = label.font.withSize(min(self.view.frame.height,self.view.frame.width) / getFontSizeCGFloatFactor(from: fontSizeStatus))
        label.layer.borderWidth = 2
        if self.traitCollection.userInterfaceStyle == .dark {
            label.layer.borderColor = UIColor.white.cgColor
        }
        else {
            label.layer.borderColor = UIColor.black.cgColor
        }
    }
    func adjustFont(for textField: UITextField, using fontSizeStatus: FontSizeStatus) {
        textField.font = textField.font?.withSize(min(self.view.frame.height,self.view.frame.width) / getFontSizeCGFloatFactor(from: fontSizeStatus))
        textField.layer.borderWidth = 2
        if self.traitCollection.userInterfaceStyle == .dark {
            textField.layer.borderColor = UIColor.white.cgColor
        }
        else {
            textField.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    func getFontSizeCGFloatFactor(from fontSizeStatus: FontSizeStatus) -> CGFloat {
        switch fontSizeStatus {
        case .small:
            return Constants.smallFontSizeFactor
        case .medium:
            return Constants.mediumFontSizeFactor
        case .big:
            return Constants.bigFontSizeFactor
        case .veryBig:
            return Constants.superBigFontSizeFactor
        case .verySmall:
            return Constants.verySmallFontSizeFactor
        }
    }
    
    struct Constants {
        
        static let verySmallFontSizeFactor: CGFloat = 5
        static let smallFontSizeFactor: CGFloat = 7
        static let mediumFontSizeFactor: CGFloat = 10
        static let bigFontSizeFactor: CGFloat = 20
        static let superBigFontSizeFactor: CGFloat = 25
        
    }
    
    func gameBadStatusAlert() {
        let alertController = UIAlertController(title: nil, message: "Game was canceled!",
                                                preferredStyle: .alert)
        alertController.addAction(.init(title: "Ok", style: .default, handler: {[weak self] _ in
            self?.performSegue(withIdentifier: "New Game", sender: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
}
