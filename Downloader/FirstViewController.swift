import UIKit

class FirstViewController: UIViewController {

	@IBOutlet var consoleView: UITextView!
	@IBOutlet var downloadButton: UIButton!
	@IBOutlet var stopButton: UIButton!
	@IBOutlet var sendButton: UIButton!
	@IBOutlet var urlTextField: UITextField!
	@IBOutlet var progressView: UIProgressView!

	private let recognizer = UISwipeGestureRecognizer()
	private let appContainer = AppContainer.shared

	override func viewDidLoad() {
		super.viewDidLoad()

		self.recognizer.direction = .down
		self.recognizer.addTarget(self, action: #selector(didSwipe))
		self.consoleView.addGestureRecognizer(self.recognizer)

		self.urlTextField.delegate = self

		self.appContainer.console.register(textView: self.consoleView)
		self.progressView.progress = 0.0
		self.urlTextField.text = "https://s08.uss.2gis.com/ver4/files/Abakan_ru_RU_map1.17_mobile-2017.12.2017.11.30.0933"

		self.appContainer.router.tabbarVC = self.tabBarController
		self.appContainer.downloader.progressHandler = { [weak self] progress in
			self?.progressView.progress = Float(progress)
		}

		self.appContainer.downloader.completionHandler = { [weak self] success in
			DispatchQueue.main.async { [weak self] in
				self?.downloadButton.setTitle("Download", for: .normal)
			}
		}
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	@IBAction func didTapSendButton() {
		log.info("💌 Did tap send button")

		self.appContainer.router.showReportError()
	}

	@IBAction func didTapStopButton() {
		log.info("Did tap stop button")

		self.appContainer.downloader.stop()
		self.downloadButton.setTitle("Download", for: .normal)
	}

	@IBAction func didTapDownloadButton() {
		log.info("Did tap download button")

		if self.appContainer.downloader.isDownloading {
			if self.appContainer.downloader.isSuspend {
				self.appContainer.downloader.resume()
				self.downloadButton.setTitle("Pause", for: .normal)
			} else {
				self.appContainer.downloader.pause()
				self.downloadButton.setTitle("Resume", for: .normal)
			}
		} else {
			if let string = self.urlTextField.text, let url = URL(string: string) {
				self.appContainer.downloader.download(url: url)
				self.downloadButton.setTitle("Pause", for: .normal)
			} else {
				self.appContainer.router.showErrorAlert(with: "Плохой УРЛ", message: "Непохоже, что можно создать урл из введённой строки 🤨")
			}
		}
	}

	@objc private func didSwipe() {
		self.urlTextField.resignFirstResponder()
	}

}

extension FirstViewController: UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		self.urlTextField.resignFirstResponder()

		return true
	}

}

