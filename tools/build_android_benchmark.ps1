param(
	[string]$BaselineRoot = '',
	[Parameter(Mandatory=$true)][string]$Godot,
	[switch]$OverlayRenderingChanges
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $BaselineRoot) { $BaselineRoot = (Get-Content (Join-Path $repo 'build/android/current-build-root.txt') -Raw).Trim() }
$config = Get-Content (Join-Path $BaselineRoot 'build-config.json') -Raw | ConvertFrom-Json
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('pb-android-benchmark-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $runRoot 'source'
New-Item -ItemType Directory -Path $source -Force | Out-Null
# Copy the source snapshot that produced the selected APK, not unrelated live edits.
& robocopy (Join-Path $BaselineRoot 'source') $source /E /XD .git .godot build /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Could not copy baseline source' }
foreach ($file in @('tools/android_benchmark.gd','tools/android_benchmark.tscn')) {
	Copy-Item -LiteralPath (Join-Path $repo $file) -Destination (Join-Path $source $file)
}
if ($OverlayRenderingChanges) {
	foreach ($file in @('scripts/core/runtime_diagnostics.gd','scripts/core/game_settings.gd','scripts/ui/visual_style_settings.gd','scripts/world/ocean_scenery.gd','scripts/autoload/sfx.gd')) {
		Copy-Item -LiteralPath (Join-Path $repo $file) -Destination (Join-Path $source $file)
	}
}
$projectPath = Join-Path $source 'project.godot'
$project = Get-Content -LiteralPath $projectPath -Raw
$project = $project.Replace('config/name="Protect Besut"', 'config/name="Protect Besut Benchmark"')
$project = $project.Replace('run/main_scene="res://scenes/game.tscn"', 'run/main_scene="res://tools/android_benchmark.tscn"')
$project = $project.Replace('[application]', "[application]`n`nconfig/benchmark_source=`"$($config.version)-$(if ($OverlayRenderingChanges) {'rendering-candidate'} else {'baseline'})`"")
Set-Content -LiteralPath $projectPath -Value $project -Encoding utf8
$presetPath = Join-Path $source 'export_presets.cfg'
$preset = Get-Content -LiteralPath $presetPath -Raw
$preset = $preset.Replace('custom_features=""', 'custom_features="android_benchmark"')
$preset = $preset.Replace('com.tidesworn.protectbesut', 'com.tidesworn.protectbesut.benchmark')
$preset = $preset.Replace('PB (Protect BESUT)', 'PB Android Benchmark')
$preset = $preset.Replace('tools/*,docs/*,addons/*,build/*,scenes/main.tscn', 'docs/*,addons/*,build/*,scenes/main.tscn')
Set-Content -LiteralPath $presetPath -Value $preset -Encoding utf8
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
$oldTestRoot = $env:TIDESWORN_TEST_ROOT
$oldJava = $env:JAVA_HOME
$oldKeyPath = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH
$oldKeyUser = $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER
$oldKeyPass = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
try {
	$env:JAVA_HOME = $config.jdk
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = Join-Path $oldAppData 'Godot/keystores/debug.keystore'
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = 'androiddebugkey'
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = 'android'
	$env:APPDATA = Join-Path $runRoot 'userdata'
	$env:LOCALAPPDATA = $env:APPDATA
	$env:TIDESWORN_TEST_ROOT = $runRoot.Replace('\','/')
	New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
	$godotData = Join-Path $env:APPDATA 'Godot'
	New-Item -ItemType Directory -Path (Join-Path $godotData 'export_templates/4.7.2.stable') -Force | Out-Null
	Copy-Item -LiteralPath (Join-Path $BaselineRoot 'export-userdata/Godot/editor_settings-4.7.tres') -Destination $godotData
	Add-Content -LiteralPath (Join-Path $godotData 'editor_settings-4.7.tres') -Value 'export/android/shutdown_adb_on_exit = false'
	foreach ($template in @('android_release.apk','android_debug.apk','version.txt')) {
		$templateSource = Join-Path $BaselineRoot ('export-userdata/Godot/export_templates/4.7.2.stable/' + $template)
		if (Test-Path -LiteralPath $templateSource) { Copy-Item -LiteralPath $templateSource -Destination (Join-Path $godotData 'export_templates/4.7.2.stable') }
	}
	Write-Output "Benchmark artifacts: $runRoot"
	foreach ($phase in @('import','export')) {
		$log = Join-Path $runRoot ($phase + '.log')
		$errors = Join-Path $runRoot ($phase + '-errors.log')
		$args = @('--headless','--recovery-mode','--path',('"'+$source+'"'))
		if ($phase -eq 'import') { $args += @('--import','--quit') }
		else { $args += @('--export-release','Android',('"'+(Join-Path $runRoot 'benchmark.apk')+'"')) }
		$process = Start-Process -FilePath $Godot -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError $errors
		$process.Handle | Out-Null
		if (-not $process.WaitForExit(600000)) { $process.Kill(); throw "Benchmark $phase timed out" }
		$process.WaitForExit()
		Get-Content -LiteralPath $errors
		if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $log,$errors -Pattern 'SCRIPT ERROR|ERROR:|Export failed' -Quiet)) { throw "Benchmark $phase failed; inspect $runRoot" }
	}
	$tools = Join-Path $config.sdk 'build-tools/36.0.0'
	& (Join-Path $tools 'apksigner.bat') verify --verbose (Join-Path $runRoot 'benchmark.apk')
	if ($LASTEXITCODE -ne 0) { throw 'Benchmark signature invalid' }
	& (Join-Path $tools 'zipalign.exe') -c -P 16 4 (Join-Path $runRoot 'benchmark.apk')
	if ($LASTEXITCODE -ne 0) { throw 'Benchmark alignment invalid' }
	$badging = & (Join-Path $tools 'aapt.exe') dump badging (Join-Path $runRoot 'benchmark.apk')
	if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect benchmark metadata' }
	if (-not ($badging -match "^package: name='com.tidesworn.protectbesut.benchmark' ")) { throw 'Refusing a benchmark APK without the dedicated package identity' }
	$badging | Select-String 'package:|native-code:' | ForEach-Object Line
	$hash = (Get-FileHash -LiteralPath (Join-Path $runRoot 'benchmark.apk') -Algorithm SHA256).Hash
	$hash | Set-Content (Join-Path $runRoot 'benchmark.sha256')
	@{package='com.tidesworn.protectbesut.benchmark'; apk_sha256=$hash; baseline_root=$BaselineRoot; adb=(Join-Path $config.sdk 'platform-tools/adb.exe'); rendering_overlay=[bool]$OverlayRenderingChanges} | ConvertTo-Json | Set-Content (Join-Path $runRoot 'benchmark-build.json')
	Write-Output "BENCHMARK_APK=$runRoot\benchmark.apk"
} finally {
	$env:APPDATA = $oldAppData
	$env:LOCALAPPDATA = $oldLocalData
	$env:TIDESWORN_TEST_ROOT = $oldTestRoot
	$env:JAVA_HOME = $oldJava
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $oldKeyPath
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $oldKeyUser
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $oldKeyPass
}
