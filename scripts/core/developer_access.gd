class_name DeveloperAccess
extends RefCounted
## The unlock phrase is never displayed, logged or saved with a journey.
const CODE_HASH := "d42b2f4921ca651a348c9be0570995f90a26ad4dc7c344a099bffb3942ee43f4"

static func matches(code: String) -> bool:
	var clean := code.strip_edges()
	return not clean.is_empty() and clean.length() <= 128 and clean.sha256_text() == CODE_HASH
