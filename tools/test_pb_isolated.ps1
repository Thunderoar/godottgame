param(
 [Parameter(Mandatory = $true)][string]$Godot,
 [string]$Scene = 'res://tools/pb_test.tscn',
 [switch]$Native,
 [switch]$ImportOnly
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('pb-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $runRoot 'userdata') -Force | Out-Null
$env:APPDATA = Join-Path $runRoot 'userdata'
$env:LOCALAPPDATA = $env:APPDATA
$env:TIDESWORN_TEST_ROOT = $runRoot.Replace('\', '/')
$arguments = @('--path', ('"' + $repo + '"'), '--audio-driver', 'Dummy')
if ($ImportOnly) { $arguments += @('--headless', '--import') }
elseif ($Native) { $arguments += @('--resolution', '1280x720', $Scene) }
else { $arguments += @('--headless', $Scene) }
$stdout = Join-Path $runRoot 'test.log'
$stderr = Join-Path $runRoot 'errors.log'
Write-Output "PB isolated artifacts: $runRoot"
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$nativeHandle = $process.Handle
$process.EnableRaisingEvents = $true
$limit = if ($ImportOnly) { 90 } else { 240 }
$clock = [Diagnostics.Stopwatch]::StartNew()
while (-not $process.WaitForExit(500)) {
 if ($clock.Elapsed.TotalSeconds -gt $limit -or ((Test-Path $stderr) -and (Select-String -Path $stderr -Pattern 'SCRIPT ERROR|Parse Error' -Quiet))) { $process.Kill(); break }
}
$process.WaitForExit()
$process.Refresh()
Write-Output ("Godot exit code: " + $process.ExitCode)
Get-Content -LiteralPath $stdout
Get-Content -LiteralPath $stderr
if ($process.ExitCode -ne 0 -or (Select-String -Path $stdout,$stderr -Pattern '\[FAIL\]|SCRIPT ERROR|ERROR:' -Quiet)) { throw 'PB verification failed.' }
if (-not $ImportOnly -and -not (Select-String -Path $stdout -Pattern '(PB test: [0-9]+ checks, PASS|PB review: PASS|tide test: [0-9]+ checks, PASS)' -Quiet)) { throw 'PB PASS summary missing.' }
