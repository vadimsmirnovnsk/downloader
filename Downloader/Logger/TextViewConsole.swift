class TextViewConsole {

	private var textView: UITextView? = nil
	private var text: String = "\n"

	func register(textView: UITextView) {
		self.textView = textView
		self.log("🖥 Did register concole view")
	}

	func log(_ text: String) {
		self.text.append(text + "\n")
		let text = self.text
		DispatchQueue.main.async { [weak self] in
			self?.textView?.text = text
		}
	}

}
