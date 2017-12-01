import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	let appContainer = AppContainer.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
		log.info("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        log.info("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        log.info("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        log.info("applicationWillTerminate")
    }

}

