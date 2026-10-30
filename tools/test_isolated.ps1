param(
	[Parameter(Mandatory = $true)][string]$Godot,
	[switch]$ImportOnly,
	[switch]$VisualReview,
	[switch]$Twilight,
	[switch]$MeiRescue,
	[switch]$Reunion,
	[switch]$OceanLevels,
	[switch]$PortalOrigin,
	[switch]$Dock,
	[switch]$Objectives,
	[switch]$Urchin,
	[switch]$Fire,
	[switch]$Stability,
	[switch]$Realtime,
	[switch]$Capture,
	[ValidateSet('1280x720', '832x480')][string]$Resolution = '1280x720',
	[ValidateSet('forest', 'village', 'interaction')][string]$Review = 'forest'
)
$ErrorActionPreference = 'Stop'
if ($OceanLevels -and ($Reunion -or $MeiRescue -or $PortalOrigin -or $Fire -or $Urchin -or $Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'OceanLevels is a separate review mode.' }
if ($Reunion -and ($MeiRescue -or $PortalOrigin -or $Fire -or $Urchin -or $Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'Reunion is a separate review mode.' }
if ($MeiRescue -and ($PortalOrigin -or $Fire -or $Urchin -or $Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'MeiRescue is a separate review mode.' }
if ($PortalOrigin -and ($Fire -or $Urchin -or $Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'PortalOrigin is a separate review mode.' }
if ($Fire -and ($Urchin -or $Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'Fire is a separate review mode.' }
if ($Urchin -and ($Twilight -or $Dock -or $Objectives -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'Urchin is a separate review mode.' }
if ($Objectives -and ($Twilight -or $Dock -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'Objectives is a separate review mode.' }
if ($Dock -and ($Twilight -or $Stability -or $VisualReview -or $ImportOnly)) { throw 'Dock is a separate review mode.' }
if ($Stability -and ($Twilight -or $ImportOnly -or $VisualReview -or $Capture)) { throw 'Stability is a separate review mode.' }
if ($Realtime -and -not $Stability) { throw 'Realtime requires Stability.' }
if ($Capture -and -not $OceanLevels -and -not $Reunion -and -not $PortalOrigin -and -not $MeiRescue -and ((-not $Twilight -and -not $Dock -and -not $Objectives -and -not $Urchin -and -not $Fire) -or $ImportOnly -or $VisualReview)) { throw 'Capture requires OceanLevels, Reunion, PortalOrigin, MeiRescue, Twilight, Dock, Objectives, Urchin or Fire and cannot be combined with import or another visual review.' }
$repo = Split-Path -Parent $PSScriptRoot
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('tidesworn-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
# A backup is evidence only; never restore over a concurrent live game.
$realSave = Join-Path $env:APPDATA 'Godot\app_userdata\Protect Besut\tidesworn_save.json'
if (Test-Path -LiteralPath $realSave) {
	Copy-Item -LiteralPath $realSave -Destination (Join-Path $runRoot 'player-save-backup.json')
}
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
$oldTestRoot = $env:TIDESWORN_TEST_ROOT
try {
	$env:APPDATA = Join-Path $runRoot 'userdata'
	$env:LOCALAPPDATA = $env:APPDATA
	$env:TIDESWORN_TEST_ROOT = $runRoot.Replace('\', '/')
	New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
	$arguments = @('--path', ('"' + $repo + '"'))
	if ($VisualReview) {
		$arguments += @('--audio-driver', 'Dummy', '--resolution', '1280x720', "res://tools/${Review}_review.tscn")
	} else {
		if ($Capture -or $Realtime) { $arguments += @('--audio-driver', 'Dummy', '--resolution', $Resolution) } else { $arguments += '--headless' }
		if ($ImportOnly) {
			$arguments += @('--import','--recovery-mode','--quit')
		} else {
			$arguments += $(if ($OceanLevels) { 'res://tools/ocean_levels_test.tscn' } elseif ($Reunion) { 'res://tools/reunion_test.tscn' } elseif ($MeiRescue) { 'res://tools/mei_ling_rescue_test.tscn' } elseif ($PortalOrigin) { 'res://tools/portal_origin_test.tscn' } elseif ($Stability) { 'res://tools/stability_test.tscn' } elseif ($Twilight) { 'res://tools/twilight_test.tscn' } elseif ($Dock) { 'res://tools/dock_conversation_test.tscn' } elseif ($Objectives) { 'res://tools/objective_tracker_test.tscn' } elseif ($Urchin) { 'res://tools/urchin_arrival_test.tscn' } elseif ($Fire) { 'res://tools/fire_arrival_test.tscn' } else { 'res://tools/tide_test.tscn' })
			if ($Stability -and -not $Realtime) { $arguments += @('--fixed-fps', '60') }
			if ($Capture) { $arguments += @('--', '--capture') }
		}
	}
	$stdout = Join-Path $runRoot 'test.log'
	$stderr = Join-Path $runRoot 'errors.log'
	Write-Output "Isolated test artifacts: $runRoot"
	$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
	$nativeHandle = $process.Handle
	$process.EnableRaisingEvents = $true
	$limit = if ($ImportOnly) { 90000 } else { 600000 }
	if (-not $process.WaitForExit($limit)) {
		$process.Kill()
		throw 'Godot exceeded the test timeout.'
	}
	$process.WaitForExit()
	$exitCode = $process.ExitCode
	Get-Content -LiteralPath $stdout
	Get-Content -LiteralPath $stderr
	if (Select-String -Path $stdout, $stderr -Pattern '\[FAIL\]|SCRIPT ERROR|ERROR:' -Quiet) { throw 'Godot reported errors.' }
	if ($exitCode -ne 0) { throw "Godot exited $exitCode." }
	$summary = if ($OceanLevels) { '^--- ocean levels: [0-9]+ checks, PASS ---$' } elseif ($Reunion) { '^--- reunion: [0-9]+ checks, PASS ---$' } elseif ($MeiRescue) { '^--- Mei Ling rescue: [0-9]+ checks, PASS ---$' } elseif ($PortalOrigin) { '^--- portal origin: [0-9]+ checks, PASS ---$' } elseif ($Stability) { '^--- stability test: [0-9]+ checks, PASS ---$' } elseif ($Twilight) { '^--- twilight test: [0-9]+ checks, PASS ---$' } elseif ($Dock) { '^--- dock conversation test: [0-9]+ checks, PASS ---$' } elseif ($Objectives) { '^--- objective tracker: [0-9]+ checks, PASS ---$' } elseif ($Urchin) { '^--- urchin arrival: [0-9]+ checks, PASS ---$' } elseif ($Fire) { '^--- fire arrival: [0-9]+ checks, PASS ---$' } else { '^--- tide test: [0-9]+ checks, PASS ---$' }
	if (-not $ImportOnly -and -not $VisualReview -and -not (Select-String -Path $stdout -Pattern $summary -Quiet)) { throw 'Acceptance PASS summary missing.' }
	if ($VisualReview -and -not (Select-String -Path $stdout -Pattern ("^${Review} review: PASS$") -Quiet)) { throw 'Visual review did not complete.' }
} finally {
	$env:APPDATA = $oldAppData
	$env:LOCALAPPDATA = $oldLocalData
	$env:TIDESWORN_TEST_ROOT = $oldTestRoot
}
