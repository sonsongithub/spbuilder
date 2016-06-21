// LiveView.swift

import UIKit
import PlaygroundSupport

// MARK: - View Controller -

private class AnswersViewController: UITableViewController, PlaygroundLiveViewMessageHandler, AnswersInputCellDelegate {
    var items: [AnswersTranscriptItem] = []
    var textHeightCache = Cache<NSString, NSNumber>()
    let insertAnimationDuration: Double = 0.4
    var previousLayoutWidth: CGFloat = 0.0
    
    static let messageCellReuseIdentifier = "AnswersMessageCell"
    static let inputCellReuseIdentifier = "AnswersInputCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let placeholderImageView = UIImageView(image: UIImage(named: "LiveViewPoster.png"))
        placeholderImageView.contentMode = .scaleAspectFit
        tableView.backgroundView = placeholderImageView
        
        tableView.backgroundColor = UIColor(white: 1.0, alpha: 0.02)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.contentInset.bottom = 72.0 // Add bottom inset for Run/Stop button
        
        tableView.register(AnswersMessageCell.self, forCellReuseIdentifier: AnswersViewController.messageCellReuseIdentifier)
        tableView.register(AnswersInputCell.self, forCellReuseIdentifier: AnswersViewController.inputCellReuseIdentifier)
        
        NotificationCenter.default().addObserver(self, selector: #selector(AnswersViewController.keyboardWillDisappear(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.width != previousLayoutWidth {
            previousLayoutWidth = view.bounds.width
            updateContentInsetsWithSize(view.bounds.size)
            
            textHeightCache.removeAllObjects()
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for (index, item) in items.enumerated() {
            if item.isEditing {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? AnswersInputCell {
                    DispatchQueue.main.after(when: DispatchTime.now()) {
                        cell.textEntryView.becomeFirstResponder()
                        cell.textEntryView.becomeFirstResponder()
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func show(_ string: String) {
        append(item: AnswersTranscriptItem(text: string), animated: true)
    }
    
    func ask(_ string: String) {
        append(item: AnswersTranscriptItem(text: "", isUserEntered: true, placeholder: string, isEditing: true), animated: true)
    }
    
    func clear() {
        items.removeAll()
        textHeightCache.removeAllObjects()
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    
    private func updateContentInsetsWithSize(_ size: CGSize) {
        let screen = view.window?.screen ?? UIScreen.main()
        // Add inset for top toolbar (when live view is not side-by-side)
        tableView.contentInset.top = size.width == screen.bounds.width / 2.0 || size.width == screen.bounds.height / 2.0 || size.width == 490.5 ? 20.0 : 72.0
    }
    
    private func append(item: AnswersTranscriptItem, animated: Bool) {
        let insertedItemIndexPath = IndexPath(row: items.count, section: 0)
        let contentBottomMargin = tableView.contentOffset.y + tableView.frame.size.height - tableView.contentInset.bottom - tableView.contentSize.height
        
        items.append(item)
        
        tableView.beginUpdates()
        tableView.insertRows(at: [insertedItemIndexPath], with: .none)
        tableView.endUpdates()
        
        if animated {
            if contentBottomMargin.distance(to: 0.0) <= tableView.rectForRow(at: insertedItemIndexPath).height {
                UIView.animate(withDuration: insertAnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                    self.tableView.scrollToRow(at: insertedItemIndexPath, at: .bottom, animated: false)
                }, completion: nil)
            }
            
            if let cell = tableView.cellForRow(at: insertedItemIndexPath) {
                let finalCellCenter = cell.center
                cell.center.y += 20
                cell.alpha = 0.0
                
                UIView.animate(withDuration: insertAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: {
                    cell.center = finalCellCenter
                    cell.alpha = 1.0
                }, completion: { (_) in
                    if item.isEditing {
                        (cell as! AnswersInputCell).textEntryView.becomeFirstResponder()
                        (cell as! AnswersInputCell).textEntryView.becomeFirstResponder()
                    }
                })
            }
        }
    }
    
    @objc private func keyboardWillDisappear(_ notification: NSNotification) {
        for (index, item) in items.enumerated() {
            if item.isEditing {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? AnswersInputCell {
                    cell.endEditing(false)
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        var cell: AnswersMessageCell
        
        if item.isUserEntered {
            let inputCell = tableView.dequeueReusableCell(withIdentifier: AnswersViewController.inputCellReuseIdentifier, for: indexPath) as! AnswersInputCell
            inputCell.delegate = self
            inputCell.indexPath = indexPath
            inputCell.messageText = item.text
            inputCell.placeholderText = item.placeholder
            inputCell.setInputEnabled(item.isEditing, animated: false)
            
            cell = inputCell
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: AnswersViewController.messageCellReuseIdentifier, for: indexPath) as! AnswersMessageCell
            cell.messageText = item.text
            cell.layoutMargins.right = AnswersInputCell.submitButtonWidthPlusSpacing + AnswersInputCell.defaultLayoutMargins.right
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.row]
        var textHeight: Double? = textHeightCache.object(forKey: item.text as NSString)?.doubleValue
        
        if textHeight == nil {
            let font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
            let boundingSize = CGSize(width: tableView.bounds.width - AnswersInputCell.defaultLayoutMargins.left - AnswersInputCell.submitButtonWidthPlusSpacing - AnswersInputCell.defaultLayoutMargins.right, height: CGFloat.greatestFiniteMagnitude)
            let textSize = (item.text as NSString).boundingRect(with: boundingSize,
                                                                options: .usesLineFragmentOrigin,
                                                                attributes: [NSFontAttributeName: font],
                                                                context: nil).size
            textHeight = Double(max(textSize.height, font.lineHeight))
            
            if !item.isEditing || item.text.characters.count == 0 {
                textHeightCache.setObject(NSNumber(value: textHeight!), forKey: item.text as NSString)
            }
        }
        
        let screen = view.window?.screen ?? UIScreen.main()
        let padding: CGFloat = (screen.bounds.width >= 1366.0 || screen.bounds.height >= 1366.0) && tableView.bounds.height >= 916.0 ? 16.0 : 8.0
        return CGFloat(floor(textHeight!)) + AnswersInputCell.defaultLayoutMargins.top + AnswersInputCell.defaultLayoutMargins.bottom + padding
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.row]
        return !item.isEditing
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) {
        let item = items[indexPath.row]
        UIPasteboard.general().string = item.text
    }
    
    @objc func tableView(tableView: UITableView, calloutTargetRectForCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) -> CGRect {
        if let messageCell = cell as? AnswersMessageCell {
            return messageCell.selectionRect
        }
        else {
            return cell.bounds
        }
    }
    
    // MARK: - PlaygroundLiveViewMessageHandler Methods
    
    func liveViewMessageConnectionOpened() {
        tableView.backgroundView = nil
        clear()
    }
    
    func liveViewMessageConnectionClosed() {
        for (index, item) in items.enumerated() {
            if item.isEditing {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = tableView.cellForRow(at: indexPath) as? AnswersInputCell {
                    cell.setInputEnabled(false, animated: false)
                }
                
                items.replaceSubrange(index...index, with: [AnswersTranscriptItem(text: item.text, isUserEntered: true)])
            }
        }
    }
    
    func receive(_ message: PlaygroundValue) {
        guard let command = AnswersLiveViewCommand(message) else {
            return
        }
        
        switch command {
        case .show(let string):
            show(string)
        case .ask(let string):
            ask(string)
        case .clear:
            clear()
        default: break
        }
    }
    
    // MARK: - AnswersInputCellDelegate Methods
    
    func cellTextDidChange(_ cell: AnswersInputCell) {
        guard let indexPath = cell.indexPath else {
            return
        }
        
        items.replaceSubrange(indexPath.row...indexPath.row, with: [AnswersTranscriptItem(text: cell.messageText, isUserEntered: true, placeholder: cell.placeholderText, isEditing: true)])
        
        if (tableView.indexPathsForVisibleRows ?? []).contains(indexPath) {
            let contentBottomMargin = tableView.contentOffset.y + tableView.frame.size.height - tableView.contentInset.bottom - tableView.contentSize.height
            
            // Force cell heights to recalculate
            tableView.beginUpdates()
            tableView.endUpdates()
            
            if contentBottomMargin >= 0.0 {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
    
    func cell(_ cell: AnswersInputCell, didSubmitText text: String) {
        guard let indexPath = cell.indexPath else {
            return
        }
        
        items.replaceSubrange(indexPath.row...indexPath.row, with: [AnswersTranscriptItem(text: text, isUserEntered: true)])
        send(AnswersLiveViewCommand.submit(text))
    }
}

// MARK: - Model -

private struct AnswersTranscriptItem {
    let text: String
    let placeholder: String?
    let isUserEntered: Bool
    let isEditing: Bool
    
    init(text: String, isUserEntered: Bool = false, placeholder: String? = nil, isEditing: Bool = false) {
        self.text = text
        self.isUserEntered = isUserEntered
        self.isEditing = isEditing
        self.placeholder = placeholder
    }
}

// MARK: - Views -

private class AnswersTextEntryView: UITextView {
    let placeholderLabel = UILabel()
    var textWidth: CGFloat = 0.0
    var placeholderWidth: CGFloat = 0.0
    
    var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set (placeholderText) {
            placeholderLabel.text = placeholderText
            placeholderWidth = placeholderText != nil ? (placeholderText! as NSString).size(attributes: [NSFontAttributeName: font!]).width : 0.0
            invalidateIntrinsicContentSize()
        }
    }
    
    override var text: String! {
        didSet {
            textWidth = (text as NSString).size(attributes: [NSFontAttributeName: font!]).width
            placeholderLabel.isHidden = text.characters.count != 0
            invalidateIntrinsicContentSize()
        }
    }
    
    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
            placeholderWidth = placeholder != nil ? (placeholder! as NSString).size(attributes: [NSFontAttributeName: font!]).width : 0.0
            textWidth = (text as NSString).size(attributes: [NSFontAttributeName: font!]).width
            invalidateIntrinsicContentSize()
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        bounces = false
        textContainerInset = UIEdgeInsets(top: 4.0, left: 2.0, bottom: 2.0, right: 2.0)
        
        placeholderLabel.textColor = UIColor(white: 25.0 / 255.0, alpha: 0.22)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7.0),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7.0),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top + 1.0)
        ])
        
        layer.cornerRadius = 5.0
        layer.borderWidth = 1.0 / UIScreen.main().scale
        layer.borderColor = UIColor(white: 0.0, alpha: 0.2).cgColor
        
        NotificationCenter.default().addObserver(self, selector: #selector(AnswersTextEntryView.textDidChange(_:)), name: .UITextViewTextDidChange, object: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textDidChange(_ note: NSNotification) {
        textWidth = (text as NSString).size(attributes: [NSFontAttributeName: font!]).width
        placeholderLabel.isHidden = text.characters.count != 0
        invalidateIntrinsicContentSize()
    }
    
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
    }
    
    override func scrollRangeToVisible(_ range: NSRange) {
    }
    
    override func intrinsicContentSize() -> CGSize {
        let contentWidth = max(textWidth, placeholderWidth) + textContainerInset.left + textContainerInset.right + 2.0 * textContainer.lineFragmentPadding + 4.0
        return CGSize(width: contentWidth, height: UIViewNoIntrinsicMetric)
    }
}

// MARK: - Cells -

private class AnswersMessageCell: UITableViewCell {
    let sourceIndicator = CAShapeLayer()
    let messageLabel = UILabel()
    
    static let defaultLayoutMargins: UIEdgeInsets = {
        let verticalPadding = ceil(UIFont.preferredFont(forTextStyle: UIFontTextStyleBody).lineHeight / 2.0)
        return UIEdgeInsets(top: verticalPadding, left: 55.0, bottom: verticalPadding, right: 20)
    }()
    
    var selectionRect: CGRect {
        var rect = messageLabel.frame
        rect.size.width = min(messageLabel.intrinsicContentSize().width, rect.size.width)
        return rect
    }
    
    var messageText: String {
        get {
            return messageLabel.text ?? ""
        }
        set (text) {
            messageLabel.text = text
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = nil
        selectionStyle = .none
        layoutMargins = AnswersMessageCell.defaultLayoutMargins
        
        sourceIndicator.fillColor = UIColor(white: 0.0, alpha: 0.2).cgColor
        layer.addSublayer(sourceIndicator)
        
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        sourceIndicator.frame = CGRect(x: layoutMargins.left - 20,
                                       y: layoutMargins.top,
                                       width: 5,
                                       height: bounds.height - layoutMargins.top - layoutMargins.bottom)
        sourceIndicator.path = UIBezierPath(roundedRect: sourceIndicator.bounds, cornerRadius: sourceIndicator.bounds.width / 2.0).cgPath
        
        messageLabel.preferredMaxLayoutWidth = bounds.width - layoutMargins.left - layoutMargins.right
        
        super.layoutSubviews()
    }
}

private protocol AnswersInputCellDelegate : AnyObject {
    func cellTextDidChange(_ cell: AnswersInputCell)
    func cell(_ cell: AnswersInputCell, didSubmitText: String)
}

private class AnswersInputCell: AnswersMessageCell, UITextViewDelegate {
    let textEntryView = AnswersTextEntryView()
    let submitButton = UIButton(type: .system)
    var inputEnabled: Bool = false
    var indexPath: IndexPath?
    
    static let keyboardDismissDelay = 1.0
    static let submitTitleString = AttributedString(string: "Submit", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.labelSize(), weight: UIFontWeightMedium)])
    static var submitButtonWidthPlusSpacing: CGFloat = {
        return ceil(submitTitleString.size().width) + 8.0 + 7.0
    }()
    
    weak var delegate: AnswersInputCellDelegate?
    
    override var messageText: String {
        get {
            return textEntryView.text
        }
        set (text) {
            super.messageText = text
            textEntryView.text = text
            submitButton.alpha = inputEnabled && text.characters.count != 0 ? 1.0 : 0.0
        }
    }
    
    var placeholderText: String? {
        get {
            return textEntryView.placeholder
        }
        set (text) {
            textEntryView.placeholder = text
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        sourceIndicator.fillColor = UIColor(white: 0.0, alpha: 0.9).cgColor
        
        textEntryView.delegate = self
        textEntryView.backgroundColor = UIColor.clear()
        textEntryView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
        textEntryView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textEntryView)
        
        textEntryView.isHidden = true
        
        submitButton.setAttributedTitle(AnswersInputCell.submitTitleString, for: [])
        submitButton.addTarget(self, action: #selector(AnswersInputCell.submit(_:)), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(submitButton)
        
        submitButton.alpha = 0.0
        
        NSLayoutConstraint.activate([
            textEntryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: -7.0),
            textEntryView.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            submitButton.leadingAnchor.constraint(equalTo: textEntryView.trailingAnchor, constant: 8.0),
            submitButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, constant: -AnswersInputCell.submitButtonWidthPlusSpacing),
            
            textEntryView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textEntryView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            submitButton.lastBaselineAnchor.constraint(equalTo: textEntryView.bottomAnchor, constant: -4)
        ])
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        indexPath = nil
        setInputEnabled(false, animated: false)
    }
    
    override var keyCommands: [UIKeyCommand] {
        return [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(AnswersInputCell.submit(_:))),
            UIKeyCommand(input: "\r", modifierFlags: .shift, action: #selector(AnswersInputCell.submit(_:))),
            UIKeyCommand(input: "\r", modifierFlags: .alphaShift, action: #selector(AnswersInputCell.submit(_:)))
        ]
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: AnyObject?) -> Bool {
        return (action == #selector(AnswersInputCell.submit(_:)))    }
    
    func setInputEnabled(_ inputEnabled: Bool, animated: Bool) {
        guard self.inputEnabled != inputEnabled else {
            return
        }
        
        messageLabel.text = textEntryView.text
        self.inputEnabled = inputEnabled
        
        let submitButtonHidden = !inputEnabled || textEntryView.text?.characters.count == 0
        if animated {
            messageLabel.alpha = inputEnabled ? 1.0 : 0.0
            textEntryView.alpha = !inputEnabled ? 1.0 : 0.0
            
            messageLabel.isHidden = false
            textEntryView.isHidden = false
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.messageLabel.alpha = inputEnabled ? 0.0 : 1.0
                self.textEntryView.alpha = !inputEnabled ? 0.0 : 1.0
                self.submitButton.alpha = submitButtonHidden ? 0.0 : 1.0
            }, completion: { (_) in
                self.messageLabel.isHidden = inputEnabled
                self.textEntryView.isHidden = !inputEnabled
                
                self.messageLabel.alpha = 1.0
                self.textEntryView.alpha = 1.0
            })
            
            textEntryView.perform(#selector(resignFirstResponder), with: nil, afterDelay: AnswersInputCell.keyboardDismissDelay)
        }
        else {
            messageLabel.isHidden = inputEnabled
            textEntryView.isHidden = !inputEnabled
            submitButton.alpha = submitButtonHidden ? 0.0 : 1.0
            textEntryView.resignFirstResponder()
        }
    }
    
    @objc func submit(_ sender: AnyObject?) {
        guard inputEnabled else {
            return
        }
        
        setInputEnabled(false, animated: true)
        delegate?.cell(self, didSubmitText: textEntryView.text)
    }
    
    // MARK: - UITextViewDelegate Methods
    
    @objc func textViewDidChange(_ textView: UITextView) {
        guard inputEnabled else {
            return
        }
        
        let finalAlpha: CGFloat = textEntryView.text?.characters.count != 0 ? 1.0 : 0.0
        
        if submitButton.alpha != finalAlpha {
            UIView.animate(withDuration: 0.2, animations: {
                self.submitButton.alpha = finalAlpha
            })
        }
        
        delegate?.cellTextDidChange(self)
    }
    
    @objc(textView:shouldChangeTextInRange:replacementText:) func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return inputEnabled
    }
}

// MARK: - LiveView Initialization -

PlaygroundPage.current.liveView = {
    let answersViewController = AnswersViewController()
    answersViewController.view.tintColor = #colorLiteral(red: 0.9960784314, green: 0.2941176471, blue: 0.1490196078, alpha: 1)
    return answersViewController
}()
