param([Parameter(Mandatory = $true)][string]$Godot, [string]$Label = 'after', [string]$Scene = 'res://tools/presentation_review.tscn', [switch]$CaptureOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$reviewRoot = Join-Path ([IO.Path]::GetTempPath()) ('tidesworn-presentation-' + $Label + '-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $reviewRoot | Out-Null
$liveSave = Join-Path $env:APPDATA 'Godot\app_userdata\Protect Besut\tidesworn_save.json'
if (Test-Path -LiteralPath $liveSave) { Copy-Item -LiteralPath $liveSave -Destination (Join-Path $reviewRoot 'player-save-backup.json') }
$previousAppData = $env:APPDATA
$previousLocalData = $env:LOCALAPPDATA
$previousTestRoot = $env:TIDESWORN_TEST_ROOT
try {
	$env:APPDATA = Join-Path $reviewRoot 'userdata'
	$env:LOCALAPPDATA = $env:APPDATA
	$env:TIDESWORN_TEST_ROOT = $reviewRoot.Replace('\','/')
	New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
	Write-Output "Presentation artifacts: $reviewRoot"
	$stdout = Join-Path $reviewRoot 'test.log'
	$stderr = Join-Path $reviewRoot 'errors.log'
	$arguments = @('--path', ('"'+$repo+'"'), '--audio-driver','Dummy','--resolution','1280x720',$Scene)
	if ($CaptureOnly) { $arguments += @('--','--capture-only') }
	$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
	$handle = $process.Handle
	$process.EnableRaisingEvents = $true
	if (-not $process.WaitForExit(300000)) { $process.Kill(); throw 'Presentation review timed out' }
	$process.WaitForExit()
	Get-Content -LiteralPath $stdout
	Get-Content -LiteralPath $stderr
	if ($process.ExitCode -ne 0 -or (Select-String -Path $stdout,$stderr -Pattern '\[FAIL\]|SCRIPT ERROR|ERROR:' -Quiet)) { throw 'Presentation review failed' }
} finally {
	$env:APPDATA = $previousAppData
	$env:LOCALAPPDATA = $previousLocalData
	$env:TIDESWORN_TEST_ROOT = $previousTestRoot
}
