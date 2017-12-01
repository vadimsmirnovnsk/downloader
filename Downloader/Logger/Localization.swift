func L10N(_ string: String) -> String {
	return NSLocalizedString(string, comment: "")
}

extension String {

	func l10n() -> String {
		return L10N(self)
	}

}
