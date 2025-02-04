//
//  DPOTPView.swift
//  DPOTPView
//
//  Created by datt on 13/11/19.
//  Copyright © 2019 datt. All rights reserved.
//

import UIKit

protocol DPOTPViewDelegate {
    func dpOTPViewAddText(_ text:String , at position:Int)
    func dpOTPViewRemoveText(_ text:String , at position:Int)
    func dpOTPViewChangePositionAt(_ position:Int)
    func dpOTPViewBecomeFirstResponder()
    func dpOTPViewResignFirstResponder()
}

@IBDesignable class DPOTPView: UIView {
    
    /** The number of textField that will be put in the DPOTPView */
    @IBInspectable var count: Int = 4
    
    /** Spaceing between textField in the DPOTPView */
    @IBInspectable var spacing: CGFloat = 8
    
    /** Circle textField */
    @IBInspectable var isCircleTextField: Bool = false
    
    /** Text font for the textField */
    @IBInspectable var fontTextField: UIFont = UIFont.systemFont(ofSize: 20) { didSet { setNeedsDisplay() } }
    
    /** Text color for the textField */
    @IBInspectable var textColorTextField: UIColor = UIColor.black
    
    /** Background color for the textField */
    @IBInspectable var backGroundColorTextField: UIColor = UIColor.clear
    
    /** Border color for the TextField */
    @IBInspectable var borderColorTextField: UIColor?
    
    /** Border color for the TextField */
    @IBInspectable var selectedBorderColorTextField: UIColor?
    
    /** Border width for the TextField */
    @IBInspectable var borderWidthTextField: CGFloat = 0.0
    
    /** Corner radius for the TextField */
    @IBInspectable var cornerRadiusTextField: CGFloat = 0.0
    
    /** Allow only Bottom Line for the TextField */
    @IBInspectable var isBottomLineTextField: Bool = false
    
    /** Tint/cursor color for the TextField */
    @IBInspectable var tintColorTextField: UIColor = UIColor.systemBlue
    
    /** Dismiss keyboard with enter last character*/
    @IBInspectable var dismissOnLastEntry: Bool = false
    
    /** Secure Text Entry*/
    @IBInspectable var isSecureTextEntry: Bool = false
    
    /** Hide cursor*/
    @IBInspectable var isCursorHidden: Bool = false {
        didSet {
            if isCursorHidden {
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                self.addGestureRecognizer(tap)
            }
        }
    }
    
    /** Dark keyboard*/
    @IBInspectable var isDarkKeyboard: Bool = false
    
    var textEdgeInsets : UIEdgeInsets?
    var editingTextEdgeInsets : UIEdgeInsets?
    
    var dpOTPViewDelegate : DPOTPViewDelegate?
    
    var text : String? {
        get {
            var str = ""
            arrTextFields.forEach { str.append($0.text ?? "") }
            return str
        } set {
            arrTextFields.forEach { $0.text = nil }
            for i in 0 ..< arrTextFields.count {
                if i < (newValue?.count ?? 0) {
                    if let txt = newValue?[i..<i+1] , let code = Int(txt) {
                        arrTextFields[i].text = String(code)
                    }
                }
            }
        }
    }
    
    fileprivate var arrTextFields : [OTPBackTextField] = []
    /** Override coder init, for IB/XIB compatibility */
    #if !TARGET_INTERFACE_BUILDER
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    /** Override common init, for manual allocation */
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    #endif
    
    func initialization() {
        
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        if arrTextFields.count != 0 { return }
        // Drawing code
        let sizeTextField = (self.bounds.width/CGFloat(count)) - (spacing)
        
        for i in 1 ... count {
            let textField = OTPBackTextField()
            textField.delegate = self
            textField.OTPBackDelegate = self
            textField.dpOTPView = self
            textField.borderStyle = .none
            textField.tag = i * 1000
            textField.tintColor = tintColorTextField
            textField.layer.backgroundColor = backGroundColorTextField.cgColor
            textField.isSecureTextEntry = isSecureTextEntry
            textField.font = fontTextField
            textField.keyboardAppearance = isDarkKeyboard ? .dark : .default
            if isCursorHidden { textField.tintColor = .clear }
            if isBottomLineTextField {
                let border = CALayer()
                border.name = "bottomBorderLayer"
                textField.removePreviouslyAddedLayer(name: border.name ?? "")
                border.backgroundColor = borderColorTextField?.cgColor
                border.frame = CGRect(x: 0, y: sizeTextField - borderWidthTextField,width : sizeTextField ,height: borderWidthTextField)
                textField.layer.addSublayer(border)
            } else {
                textField.layer.borderColor = borderColorTextField?.cgColor
                textField.layer.borderWidth = borderWidthTextField
                if isCircleTextField {
                    textField.layer.cornerRadius = sizeTextField / 2
                    textField.layer.masksToBounds = true
                } else {
                    textField.layer.cornerRadius = cornerRadiusTextField
                    textField.layer.masksToBounds = cornerRadiusTextField > 0.0
                }
            }
            textField.textColor = textColorTextField
            textField.textAlignment = .center
            textField.keyboardType = .asciiCapableNumberPad
            if #available(iOS 12.0, *) {
                textField.textContentType = .oneTimeCode
            }
            
            textField.frame = CGRect(x:(CGFloat(i-1) * sizeTextField) + (CGFloat(i) * spacing/2) + (CGFloat(i-1) * spacing/2)  , y: (self.bounds.height - sizeTextField)/2 , width: sizeTextField, height: sizeTextField)
            
            arrTextFields.append(textField)
            self.addSubview(textField)
        }
        super.draw(rect)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        OperationQueue.main.addOperation({
            if #available(iOS 13.0, *) {
                UIMenuController.shared.hideMenu()
            } else {
                UIMenuController.shared.setMenuVisible(false, animated: false)
            }
        })
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func becomeFirstResponder() -> Bool {
        if isCursorHidden {
            for i in 0 ..< arrTextFields.count {
                if arrTextFields[i].text?.count == 0 {
                    _ = arrTextFields[i].becomeFirstResponder()
                    break
                } else if (arrTextFields.count - 1) == i{
                    _ = arrTextFields[i].becomeFirstResponder()
                }
            }
        } else {
            _ = arrTextFields[0].becomeFirstResponder()
        }
        dpOTPViewDelegate?.dpOTPViewBecomeFirstResponder()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        arrTextFields.forEach { (textField) in
            _ = textField.resignFirstResponder()
        }
        dpOTPViewDelegate?.dpOTPViewResignFirstResponder()
        return super.resignFirstResponder()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        _ = self.becomeFirstResponder()
    }
    
    func validate() -> Bool {
        var isValid = true
        arrTextFields.forEach { (textField) in
            if Int(textField.text ?? "") == nil {
                isValid = false
            }
        }
        return isValid
    }
}

extension DPOTPView : UITextFieldDelegate , OTPBackTextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if isCursorHidden {
         (textField as? OTPBackTextField)?.addUnselectedBorderColor()
         _ = self.becomeFirstResponder()
        }
        dpOTPViewDelegate?.dpOTPViewChangePositionAt(textField.tag/1000 - 1)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.trimmingCharacters(in: CharacterSet.whitespaces).count != 0 {
            textField.text = string
            if textField.tag < count*1000 {
                let next = textField.superview?.viewWithTag((textField.tag/1000 + 1)*1000)
                next?.becomeFirstResponder()
            } else if textField.tag == count*1000 && dismissOnLastEntry {
                textField.resignFirstResponder()
            }
        } else if string.count == 0 { // is backspace
            textField.text = ""
        }
        dpOTPViewDelegate?.dpOTPViewAddText(text ?? "", at: textField.tag/1000 - 1)
        return false
    }
    
    func textFieldDidDelete(_ textField: UITextField) {
        if textField.tag > 1000 , let next = textField.superview?.viewWithTag((textField.tag/1000 - 1)*1000) as? UITextField {
            next.text = ""
            next.becomeFirstResponder()
            dpOTPViewDelegate?.dpOTPViewRemoveText(text ?? "", at: next.tag/1000 - 1)
        }
    }
}

protocol OTPBackTextFieldDelegate {
    func textFieldDidDelete(_ textField : UITextField)
}


class OTPBackTextField: UITextField {
    
    var OTPBackDelegate : OTPBackTextFieldDelegate?
    weak var dpOTPView : DPOTPView!
    
    override func deleteBackward() {
        super.deleteBackward()
        OTPBackDelegate?.textFieldDidDelete(self)
    }
    
    override func becomeFirstResponder() -> Bool {
        addSelectedBorderColor()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        addUnselectedBorderColor()
        return super.resignFirstResponder()
    }
    
    fileprivate func addSelectedBorderColor() {
        if let selectedBorderColor = dpOTPView.selectedBorderColorTextField {
            if dpOTPView.isBottomLineTextField {
                addBottomLine(selectedBorderColor)
            }  else {
                layer.borderColor = selectedBorderColor.cgColor
            }
        }
    }
    
    fileprivate func addUnselectedBorderColor() {
        if let unselectedBorderColor = dpOTPView.borderColorTextField {
            if dpOTPView.isBottomLineTextField {
                addBottomLine(unselectedBorderColor)
            }  else {
                layer.borderColor = unselectedBorderColor.cgColor
            }
        }
    }
    
    fileprivate func addBottomLine(_ color : UIColor) {
        let border = CALayer()
        border.name = "bottomBorderLayer"
        removePreviouslyAddedLayer(name: border.name ?? "")
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.width - dpOTPView.borderWidthTextField,width : self.frame.width ,height: dpOTPView.borderWidthTextField)
        self.layer.addSublayer(border)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: dpOTPView.textEdgeInsets ?? UIEdgeInsets.zero)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: dpOTPView.editingTextEdgeInsets ?? UIEdgeInsets.zero)
    }
    
    fileprivate func removePreviouslyAddedLayer(name : String) {
        if self.layer.sublayers?.count ?? 0 > 0 {
            self.layer.sublayers?.forEach {
                if $0.name == name {
                    $0.removeFromSuperlayer()
                }
            }
        }
    }
}


extension String {
    subscript(_ i: Int) -> String {
        let idx1 = index(startIndex, offsetBy: i)
        let idx2 = index(idx1, offsetBy: 1)
        return String(self[idx1..<idx2])
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start ..< end])
    }
    
    subscript (r: CountableClosedRange<Int>) -> String {
        let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[startIndex...endIndex])
    }
}
