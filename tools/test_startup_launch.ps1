param(
	[Parameter(Mandatory = $true)][string]$Godot,
	[switch]$Native,
	[ValidateSet('1280x720', '832x480')][string]$Resolution = '1280x720'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
# Refresh class metadata and imported resources before exercising normal startup.
& (Join-Path $PSScriptRoot 'test_isolated.ps1') -Godot $Godot -ImportOnly
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('pb-startup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $runRoot 'userdata') -Force | Out-Null
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
$oldTestRoot = $env:TIDESWORN_TEST_ROOT
try {
	$env:APPDATA = Join-Path $runRoot 'userdata'
	$env:LOCALAPPDATA = $env:APPDATA
	$env:TIDESWORN_TEST_ROOT = $runRoot.Replace('\', '/')
	$arguments = @('--path', ('"' + $repo + '"'), '--audio-driver', 'Dummy', '--script', 'res://tools/startup_launch_test.gd')
	if ($Native) { $arguments += @('--resolution', $Resolution) } else { $arguments += '--headless' }
	$stdout = Join-Path $runRoot 'test.log'
	$stderr = Join-Path $runRoot 'errors.log'
	Write-Output "Startup launch artifacts: $runRoot"
	$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
	$nativeHandle = $process.Handle
	$process.EnableRaisingEvents = $true
	if (-not $process.WaitForExit(60000)) {
		$process.Kill()
		throw 'Startup launch exceeded the test timeout.'
	}
	$process.WaitForExit()
	Get-Content -LiteralPath $stdout
	Get-Content -LiteralPath $stderr
	if ($process.ExitCode -ne 0 -or (Select-String -Path $stdout, $stderr -Pattern '\[FAIL\]|SCRIPT ERROR|ERROR:' -Quiet)) { throw 'Startup launch failed.' }
	if (-not (Select-String -Path $stdout -Pattern '^--- startup launch: PASS ---$' -Quiet)) { throw 'Startup launch PASS summary missing.' }
} finally {
	$env:APPDATA = $oldAppData
	$env:LOCALAPPDATA = $oldLocalData
	$env:TIDESWORN_TEST_ROOT = $oldTestRoot
}
