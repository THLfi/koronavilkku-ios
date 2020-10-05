import UIKit

class TokenCodeField: UITextField {
    private let onChangeCallback: () -> Void
    
    init(onChange: @escaping () -> Void) {
        onChangeCallback = onChange
        super.init(frame: .zero)
        
        backgroundColor = UIColor.Greyscale.white
        setElevation(.elevation1)
        font = UIFont.coronaCode
        layer.cornerRadius = 8
        textAlignment = .center
        keyboardType = .asciiCapableNumberPad
        autocorrectionType = .no
        delegate = self
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
    
    @objc func editingChanged() {
        onChangeCallback()
    }
}

extension TokenCodeField : UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let oldLength = textField.text?.count ?? 0
        let replacementLength = string.count
        let rangeLength = range.length
        
        let newLength = oldLength - rangeLength + replacementLength
        
        let returnPressed = string.range(of: "\n") != nil
        
        return newLength <= 12 || returnPressed
    }
}
