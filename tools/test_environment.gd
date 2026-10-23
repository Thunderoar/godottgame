class_name TestEnvironment
extends RefCounted
## Shared refusal for harnesses that create journeys, change settings or delete saves.

static func require_isolation() -> bool:
	var expected := OS.get_environment("TIDESWORN_TEST_ROOT").simplify_path()
	var actual := OS.get_user_data_dir().simplify_path()
	if expected.is_empty() or not actual.begins_with(expected.trim_suffix("/") + "/"):
		push_error("Refusing test/capture outside verified isolated user data. Set TIDESWORN_TEST_ROOT and XDG_DATA_HOME; see docs/ACCEPTANCE_TESTS.md.")
		return false
	print("Verified isolated user data: ", actual)
	return true
