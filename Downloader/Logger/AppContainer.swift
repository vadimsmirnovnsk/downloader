public class AppContainer {

	public static var shared: AppContainer = {
		return AppContainer()
	}()

	internal let console = TextViewConsole()

	private init() {
		Logger.configure()
	}

	internal lazy var router: Router = { [unowned self] in
		return Router(container: self)
	}()

	internal lazy var downloader: Downloader = {
		return Downloader()
	}()

}
