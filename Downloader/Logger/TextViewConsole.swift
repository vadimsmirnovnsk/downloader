class TextViewConsole {

	private var textView: UITextView? = nil
	private var text: String = "\n"

	func register(textView: UITextView) {
		self.textView = textView
		self.log("🖥 Did register concole view")
	}

	func log(_ text: String) {
//		DispatchQueue.main.async { [weak self] in
//			self?.textView?.text.append(text + "\n")
//		}
	}

}
