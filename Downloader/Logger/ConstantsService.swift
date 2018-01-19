internal struct ConstantsService
{
	static let currentVersion = Bundle.main.infoDictionary?[String(kCFBundleVersionKey)]! as! String
	static let currentBuild = Bundle.main.infoDictionary?["CFBundleShortVersionString"]! as! String
	static let platformOSName = "iOS"
	static let platformOSVersion = UIDevice.current.systemVersion
	static let currentLanguage = Locale.preferredLanguages.first ?? "en-US"
	static let isRussian = ConstantsService.currentLanguage.hasPrefix("ru")
	static let defaultUrlString = "http://10.54.201.79:8888/encode-gzip-plain-range/Almetevsk_data.2gis"
	//"http://10.54.201.79:8888/encode-gzip-gzip-range/Almetevsk_data.2gis"//"https://s08.uss.2gis.com/ver4/files/Abakan_ru_RU_map1.17_mobile-2017.12.2017.11.30.0933"
}
