param(
	[Parameter(Mandatory = $true)][string]$Godot,
	[switch]$ImportOnly,
	[switch]$VisualReview,
	[ValidateSet('forest', 'village', 'interaction')][string]$Review = 'forest'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('tidesworn-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
# A backup is evidence only; never restore over a concurrent live game.
$realSave = Join-Path $env:APPDATA 'Godot\app_userdata\Save The World\tidesworn_save.json'
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
		$arguments += '--headless'
		if ($ImportOnly) { $arguments += '--import' } else { $arguments += 'res://tools/tide_test.tscn' }
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
	if (-not $ImportOnly -and -not $VisualReview -and -not (Select-String -Path $stdout -Pattern '^--- tide test: [0-9]+ checks, PASS ---$' -Quiet)) { throw 'Acceptance PASS summary missing.' }
	if ($VisualReview -and -not (Select-String -Path $stdout -Pattern ("^${Review} review: PASS$") -Quiet)) { throw 'Visual review did not complete.' }
} finally {
	$env:APPDATA = $oldAppData
	$env:LOCALAPPDATA = $oldLocalData
	$env:TIDESWORN_TEST_ROOT = $oldTestRoot
}
