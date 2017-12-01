class Downloader: NSObject {

	private let backgroundCfgRestricted = URLSessionConfiguration.background(withIdentifier: "com.2gis.test.session")

	internal lazy var backgroundSessionRestricted: Foundation.URLSession = {
		[unowned self] in

		return URLSession(configuration: self.backgroundCfgRestricted,
						  delegate: self,
						  delegateQueue: self.operationQueue)
	}()

	public private(set) var isDownloading = false
	public private(set) var isSuspend = false

	private let operationQueue = OperationQueue()
	private var currentDataTask: URLSessionDataTask?
	private var expectedContentLength: Int64 = 0

	public var progressHandler: ((Double) -> Void)?
	public var completionHandler: ((Bool) -> Void)?
	private var dataToDownload: Data?

	override init() {

		super.init()

		self.operationQueue.maxConcurrentOperationCount = 1

		let sharedContainerIdentifier = Bundle.main.bundleIdentifier

		// https://developer.apple.com/reference/foundation/urlsessionconfiguration/

		// Для загрузок core (background wifi + 3g)
		// Discretionary должен быть false, иначе на 9-ой оси не работают фоновые
		// обновления по 3G. При дропе 9 оси можно переключить на true.
		self.backgroundCfgRestricted.httpMaximumConnectionsPerHost = 24
		self.backgroundCfgRestricted.isDiscretionary = true
		self.backgroundCfgRestricted.allowsCellularAccess = false
		self.backgroundCfgRestricted.timeoutIntervalForRequest = 300
		self.backgroundCfgRestricted.sessionSendsLaunchEvents = true
		// Есть шанс, что это поможет с ошибками, которые не проходят без перезагрузки девайса.
		// https://github.com/dropbox/dropbox-sdk-obj-c/issues/60
		self.backgroundCfgRestricted.sharedContainerIdentifier = sharedContainerIdentifier
		log.info("[HTTP Network] Did create restricted configuration: (discretionary: \(self.backgroundCfgRestricted.isDiscretionary), allowsCellularAccess: \(self.backgroundCfgRestricted.allowsCellularAccess))")
	}

	func download(url: URL) {
		let task = self.backgroundSessionRestricted.dataTask(with: url)
		self.currentDataTask = task
		self.isDownloading = true
		self.isSuspend = false

		log.info("🆕 Did create download task with identifier: \(task.taskIdentifier)")

		self.currentDataTask?.resume()
	}

	func stop() {
		if let task = self.currentDataTask {
			log.info("Will cancel download task with identifier: \(task.taskIdentifier)")
		}

		self.currentDataTask?.cancel()
		self.currentDataTask = nil
		self.dataToDownload = nil
		self.expectedContentLength = 0
		self.isDownloading = false
		self.isSuspend = false
	}

	func pause() {
		self.currentDataTask?.suspend()
		self.isSuspend = true
	}

	func resume() {
		self.currentDataTask?.resume()
		self.isSuspend = false
	}

}

extension Downloader: URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

	// MARK: Download Task Delegate

	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		log.info("🌝 urlSessionDidFinishEvents forBackgroundURLSession: \(session)")
	}

	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		log.info("✅ urlSession didFinishDownloading to location: \(location)")
	}

	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		// В этом методе делегата мы можем обработать сразу три события и после каждого из событий, observer может поменяться,
		// поэтому в каждом из методов заново пытаемся достать observer
		self.tryProcessRedirect(downloadTask: downloadTask)
		self.tryProcessReceiveMetadata(downloadTask: downloadTask)
		self.tryProcessProgressChange(downloadTask: downloadTask, downloaded: totalBytesWritten, total: totalBytesExpectedToWrite)
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error = error {
			log.info("[HTTP Network] ⛔️ Did complete task \(task.taskIdentifier) with error \(error)")
		} else {
			if let response = task.response as? HTTPURLResponse {
				var rangeHeader = ""
				if let range = response.allHeaderFields["Range"] {
					rangeHeader = "Range : \(range), "
				}

				let contentLengthHeader = "Content-Length : \(response.allHeaderFields["Content-Length"] ?? "")"
				let responseString = "Status code : \(response.statusCode), \(rangeHeader)\(contentLengthHeader)"

				log.info("[HTTP Network] ✅ Did complete task: [identifier: <\(task.taskIdentifier)>, response: \(responseString)]")

				// Clear all
				self.stop()
			}
			else {
				log.info("[HTTP Network] ✅ Did complete with unrecognized response task: [identifier: <\(task.taskIdentifier)>]")
			}

			log.info("[HTTP Network] ✅ Did complete task \(task.taskIdentifier)")
			self.completionHandler?(error != nil)
		}

	}

	// MARK: observer methods

	private func tryProcessRedirect(downloadTask: URLSessionDownloadTask) {
		guard let finalUrl = downloadTask.currentRequest?.url,
			let originalUrl = downloadTask.originalRequest?.url,
			finalUrl != originalUrl else { return }

			log.info("[HTTP Network]❗️Did redirect download task: [identifier: <\(downloadTask.taskIdentifier)>, to url: \(finalUrl), from url: \(originalUrl)]")
	}

	private func tryProcessReceiveMetadata(downloadTask: URLSessionDownloadTask) {
		guard let response = downloadTask.response as? HTTPURLResponse else { return }

		log.info("[HTTP Network] 📩 Did receive metadata of \(downloadTask.taskIdentifier), [status code: \(response.statusCode)]")
	}

	private func tryProcessProgressChange(downloadTask: URLSessionDownloadTask, downloaded: Int64, total: Int64) {
		let progress = 100.0 * Double(downloaded) / Double(total)
		let barsCount = Int(progress / 10.0)
		let progressArray: [String] = Array(0...9).map { return $0 < barsCount ? "*" : " "}
		let progressString = progressArray.joined()

		log.info("[HTTP Network] ⏬ Progress of \(downloadTask.taskIdentifier), [\(progressString)] \(Int(progress))% (\(downloaded) / \(total) bytes)")
	}

	// MARK: Data task

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if var savedData = self.dataToDownload {
			savedData.append(data)
			self.dataToDownload = savedData
		} else {
			self.dataToDownload = data
		}

		if let downloadedData = self.dataToDownload {
			let absoluteProgress = Double(downloadedData.count) / Double(self.expectedContentLength)
			let progress = 100.0 * absoluteProgress
			let barsCount = Int(progress / 10.0)
			let progressArray: [String] = Array(0...9).map { return $0 < barsCount ? "*" : " "}
			let progressString = progressArray.joined()
			log.info("[HTTP Network] ⏬ Progress of \(dataTask.taskIdentifier), [\(progressString)] \(Int(progress))% (\(downloadedData.count) / \(self.expectedContentLength) bytes)")

			DispatchQueue.main.async { [weak self] in
				self?.progressHandler?(absoluteProgress)
			}
		}
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
		log.info("didBecome downloadTask: \(dataTask.taskIdentifier)")
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
		log.info("didBecome streamTask: \(dataTask.taskIdentifier)")
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		completionHandler(.allow)

		self.expectedContentLength = response.expectedContentLength
		log.info("didReceive response: \(dataTask.taskIdentifier)")
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
		log.info("willCacheResponse response: \(dataTask.taskIdentifier)")

		completionHandler(proposedResponse)
	}

}
