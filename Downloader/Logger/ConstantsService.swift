internal struct ConstantsService
{
	static let currentVersion = Bundle.main.infoDictionary?[String(kCFBundleVersionKey)]! as! String
	static let currentBuild = Bundle.main.infoDictionary?["CFBundleShortVersionString"]! as! String
	static let platformOSName = "iOS"
	static let platformOSVersion = UIDevice.current.systemVersion
	static let currentLanguage = Locale.preferredLanguages.first ?? "en-US"
	static let isRussian = ConstantsService.currentLanguage.hasPrefix("ru")
}
