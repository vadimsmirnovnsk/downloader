let log = ConsoleLogger()
let xcLog = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

class ConsoleLogger {

	func info(_ text: String) {
		AppContainer.shared.console.log(text)
		xcLog.info(text)
	}

}

class Logger {

	static let logFilePath: URL = {
		let url = Logger.cacheDirectory.appendingPathComponent("brawlstats.log")
		return url
	}()

	static let cacheDirectory: URL = {
		let cacheDirectoryURL = FileManager.cacheDirectoryURL()
		return cacheDirectoryURL
	}()

	static func configure() {
		// Create a destination for the system console log (via NSLog)
		let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")

		// Optionally set some configuration options
		#if DEBUG
			systemDestination.outputLevel = .debug
		#else
			systemDestination.outputLevel = .info
		#endif

		systemDestination.showLogIdentifier = false
		systemDestination.showFunctionName = true
		systemDestination.showThreadName = true
		systemDestination.showLevel = true
		systemDestination.showFileName = true
		systemDestination.showLineNumber = true
		systemDestination.showDate = true

		// Add the destination to the logger
		xcLog.add(destination: systemDestination)

		// Create a file log destination
		let fileDestination = FileDestination(writeToFile: Logger.logFilePath, identifier: "advancedLogger.fileDestination")

		// Optionally set some configuration options
		fileDestination.outputLevel = .info
		fileDestination.showLogIdentifier = false
		fileDestination.showFunctionName = true
		fileDestination.showThreadName = true
		fileDestination.showLevel = true
		fileDestination.showFileName = true
		fileDestination.showLineNumber = false
		fileDestination.showDate = true

		// Process this destination in the background
		fileDestination.logQueue = XCGLogger.logQueue

		// Add the destination to the logger
		xcLog.add(destination: fileDestination)

		// Add basic app info, version info etc, to the start of the logs
		xcLog.logAppDetails()

		logCurrentRunDetails()
	}

	static func logAttachmentData() -> Data {
		let filePath = Logger.cacheDirectory.appendingPathComponent("brawlstats.log")
		if let fileData = try? Data(contentsOf: filePath) {
			return fileData
		}
		
		return Data.init()
	}

	fileprivate static func logCurrentRunDetails() {
		xcLog.info("| Application Version: \(ConstantsService.currentVersion)")
		xcLog.info("| Application Build: \(ConstantsService.currentBuild)")
		xcLog.info("| Platform OS: \(ConstantsService.platformOSName) \(ConstantsService.platformOSVersion)")
	}

}

extension XCGLogger {

	func filePath() -> URL {
		return Logger.logFilePath
	}

}
