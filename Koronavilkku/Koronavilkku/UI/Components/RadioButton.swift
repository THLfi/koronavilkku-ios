import UIKit

class RadioButton<Value: Equatable>: Checkbox {
    let value: Value
    
    weak var radioGroup: RadioButtonGroup<Value>?
    
    init(value: Value, label: String) {
        self.value = value
        super.init(label: label) { _ in }
        
        selectedColor = .clear
        acceptButton.setBackgroundImage(UIImage(named: "radio-off"), for: .normal)
        acceptButton.setBackgroundImage(UIImage(named: "radio-on"), for: .selected)
        acceptButton.layer.cornerRadius = 0
        acceptButton.layer.borderWidth = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func tapHandler() {
        isChecked = true
        radioGroup?.value = value
    }
}

/// Group of mutually exclusive radio buttons
///
/// This is not an UI element, because it does not have to be. It only
/// provides a mechanism to link the radio buttons together.
///
/// - Important: You need to retain a reference to this object because
/// otherwise it will be released and the radio buttons lose their link.
class RadioButtonGroup<Value: Equatable> {
    private let radioButtons: [RadioButton<Value>]
    private var onChangeHandler: ((Value) -> ())?
    
    var value: Value? {
        didSet {
            guard let value = value, value != oldValue else { return }
            
            for button in radioButtons {
                if button.value != value {
                    button.isChecked = false
                }
            }
            
            onChangeHandler?(value)
        }
    }
    
    init(_ radioButtons: [RadioButton<Value>]) {
        self.radioButtons = radioButtons
        
        for button in radioButtons {
            button.radioGroup = self
        }
    }
    
    func onChange(handler: @escaping (Value) -> ()) {
        self.onChangeHandler = handler
    }
}
