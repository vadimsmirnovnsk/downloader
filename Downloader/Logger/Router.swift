import MessageUI
import StoreKit

class Router: NSObject, MFMailComposeViewControllerDelegate {

	var tabbarVC: UITabBarController?

	private let container: AppContainer

	init(container: AppContainer) {
		self.container = container
	}

	func showErrorAlert(with title: String, message: String) {
		let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Окей",
										 style: .destructive, handler: nil)

		alertController.addAction(cancelAction)

		DispatchQueue.main.async { [weak self] in
			self?.tabbarVC?.present(alertController, animated: true, completion: nil)
		}
	}

	func showReportError() {
		guard self.canSendMail() else {
			self.showNoMailAlert()
			return
		}

		let mailVC = MFMailComposeViewController(nibName: nil, bundle: nil)
		mailVC.mailComposeDelegate = self
		mailVC.setToRecipients(["s.vidyuk@2Gis.ru"])
		mailVC.setSubject("Логи загрузки")
		mailVC.setMessageBody(L10N("Логи загрузки"), isHTML: false)
		if let data = try? Data(contentsOf: xcLog.filePath()) {
			mailVC.addAttachmentData(data, mimeType: "text/plain", fileName: "logs.txt")
		}
		self.tabbarVC?.present(mailVC, animated: true, completion: nil)
	}

	// MARK: MFMessageComposeViewControllerDelegate

	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		self.tabbarVC?.dismiss(animated: true, completion: nil)
	}

	private func canSendMail() -> Bool {
		let canSend = MFMailComposeViewController.canSendMail()
		return canSend
	}

	private func showNoMailAlert() {
		let title = "😔"
		let message = "На девайсе нет email клиента"
		let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Окей",
										 style: .destructive, handler: nil)

		alertController.addAction(cancelAction)

		DispatchQueue.main.async { [weak self] in
			self?.tabbarVC?.present(alertController, animated: true, completion: nil)
		}
	}

}
