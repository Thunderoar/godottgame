param(
	[Parameter(Mandatory=$true)][string]$RunRoot,
	[Parameter(Mandatory=$true)][string]$Device,
	[Parameter(Mandatory=$true)][string]$OutputDirectory,
	[string]$Adb = '',
	[switch]$SkipInstall
)
$ErrorActionPreference='Stop'
$package='com.tidesworn.protectbesut.benchmark'
$build=Get-Content (Join-Path $RunRoot 'benchmark-build.json') -Raw | ConvertFrom-Json
if ($build.package -ne $package -or (Get-FileHash -LiteralPath (Join-Path $RunRoot 'benchmark.apk') -Algorithm SHA256).Hash -ne $build.apk_sha256) { throw 'Benchmark identity/hash verification failed' }
if (-not $Adb) { $Adb=$build.adb }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
& $Adb connect $Device
if (-not $SkipInstall) {
	& $Adb -s $Device install -r --no-streaming (Join-Path $RunRoot 'benchmark.apk')
	if ($LASTEXITCODE -ne 0) { throw 'Dedicated benchmark installation failed' }
}
& $Adb -s $Device shell am force-stop $package
& $Adb -s $Device shell dumpsys battery | Set-Content (Join-Path $OutputDirectory 'battery-start.txt')
& $Adb -s $Device shell am start -n "$package/com.godot.game.GodotAppLauncher"
$benchmarkProcess=''
for ($attempt=0; $attempt -lt 10 -and -not $benchmarkProcess; $attempt++) {
	Start-Sleep -Seconds 1
	$benchmarkProcess=([string](& $Adb -s $Device shell pidof $package)).Trim()
}
if (-not $benchmarkProcess) { throw 'Benchmark process did not start' }
$benchmarkProcess | Set-Content (Join-Path $OutputDirectory 'device.pid')
$records=@{}
$deadline=[DateTime]::UtcNow.AddMinutes(12)
$complete=$false
while ([DateTime]::UtcNow -lt $deadline) {
	$lines=@(& $Adb -s $Device logcat -d -v raw "--pid=$benchmarkProcess" -s 'godot:I' '*:S')
	if ($LASTEXITCODE -ne 0) { & $Adb connect $Device; Start-Sleep -Seconds 5; continue }
	$lines | Set-Content (Join-Path $OutputDirectory 'logcat.txt')
	foreach ($line in $lines) {
		if ($line.StartsWith('ANDROID_BENCHMARK_SAMPLE ')) {
			$record=$line.Substring('ANDROID_BENCHMARK_SAMPLE '.Length) | ConvertFrom-Json
			$key="$($record.pass_index)/$($record.profile)/$($record.scenario)"
			if (-not $records.ContainsKey($key)) {
				$records[$key]=$record
				Write-Output ('[{0}] {1}: {2:N1} FPS; p95 {3:N1} ms' -f $key,$record.build,$record.fps,$record.frame_ms.p95)
			}
		}
		if ($line -match '^ANDROID_BENCHMARK_DONE 24$') { $complete=$true }
	}
	@($records.Values) | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $OutputDirectory 'samples.json')
	if ($lines -match 'SCRIPT ERROR|ERROR:') { throw 'Benchmark reported a runtime error; inspect its log' }
	if ($complete) { break }
	if (-not ([string](& $Adb -s $Device shell pidof $package)).Trim()) { throw 'Benchmark exited before completion' }
	Start-Sleep -Seconds 15
}
& $Adb -s $Device shell dumpsys battery | Set-Content (Join-Path $OutputDirectory 'battery-end.txt')
if (-not $complete -or $records.Count -ne 24) { throw "Incomplete benchmark: $($records.Count)/24 samples" }
Write-Output "ANDROID BENCHMARK: 24/24 samples complete; evidence $OutputDirectory"
