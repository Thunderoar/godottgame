param(
	[string]$TemplateSource = (Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable\android_source.zip'),
	[string]$AndroidJar = (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platforms\android-37.0\android.jar'),
	[string]$JavaHome = $env:JAVA_HOME,
	[switch]$InstallGradleTemplate
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $JavaHome) { $JavaHome = Split-Path -Parent (Split-Path -Parent (Get-Command javac).Source) }
$javac = Join-Path $JavaHome 'bin\javac.exe'
$jar = Join-Path $JavaHome 'bin\jar.exe'
foreach ($required in @($TemplateSource, $AndroidJar, $javac, $jar)) {
	if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing build prerequisite: $required" }
}
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('besut-hms-bridge-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
Write-Output "HMS bridge build artifacts: $runRoot"
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Expand-ZipEntry([string]$Archive, [string]$Entry, [string]$Destination) {
	$zip = [IO.Compression.ZipFile]::OpenRead($Archive)
	try {
		$item = $zip.GetEntry($Entry)
		if ($null -eq $item) { throw "Missing $Entry in $Archive" }
		[IO.Compression.ZipFileExtensions]::ExtractToFile($item, $Destination, $true)
	} finally { $zip.Dispose() }
}
$scan = Join-Path $runRoot 'scan.aar'
Invoke-WebRequest -Uri 'https://developer.huawei.com/repo/com/huawei/hms/scan/2.15.0.301/scan-2.15.0.301.aar' -OutFile $scan
if ((Get-FileHash -LiteralPath $scan -Algorithm SHA256).Hash -ne 'E0997C952484AD04523D2AA97A30E249E5CBE693932B509B54F073F1312378F3') {
	throw 'Huawei Scan Kit archive checksum mismatch.'
}
$godotAar = Join-Path $runRoot 'godot.aar'
$godotJar = Join-Path $runRoot 'godot.jar'
$scanJar = Join-Path $runRoot 'scan.jar'
Expand-ZipEntry $TemplateSource 'libs/release/godot-lib.template_release.aar' $godotAar
Expand-ZipEntry $godotAar 'classes.jar' $godotJar
Expand-ZipEntry $scan 'classes.jar' $scanJar
$classes = Join-Path $runRoot 'classes'
$package = Join-Path $runRoot 'package'
New-Item -ItemType Directory -Path $classes, $package | Out-Null
& $javac --release 17 -encoding UTF-8 -classpath "$AndroidJar;$godotJar;$scanJar" -d $classes (Join-Path $PSScriptRoot 'android_hms\ProtectBesutHms.java')
if ($LASTEXITCODE -ne 0) { throw 'HMS bridge Java compilation failed.' }
& $jar --create --file (Join-Path $package 'classes.jar') -C $classes .
if ($LASTEXITCODE -ne 0) { throw 'HMS bridge archive creation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'android_hms\AndroidManifest.xml') -Destination $package
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'android_hms\consumer-rules.pro') -Destination (Join-Path $package 'proguard.txt')
$built = Join-Path $runRoot 'ProtectBesutHms.aar'
[IO.Compression.ZipFile]::CreateFromDirectory($package, $built)
$destination = Join-Path $repo 'addons\pb_hms_scan\bin'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -LiteralPath $built -Destination (Join-Path $destination 'ProtectBesutHms.aar') -Force
Write-Output 'HMS bridge compiled successfully (Java 17 bytecode).'
if ($InstallGradleTemplate) {
	$androidRoot = Join-Path $repo 'android'
	$templateDestination = Join-Path $androidRoot 'build'
	if (Test-Path -LiteralPath $templateDestination) { throw 'Android build template already exists; refresh it through Godot if required.' }
	New-Item -ItemType Directory -Force -Path $androidRoot | Out-Null
	[IO.Compression.ZipFile]::ExtractToDirectory($TemplateSource, $templateDestination)
	[IO.File]::WriteAllText((Join-Path $templateDestination '.gdignore'), '')
	$templateVersion = Split-Path -Leaf (Split-Path -Parent $TemplateSource)
	[IO.File]::WriteAllText((Join-Path $androidRoot '.build_version'), $templateVersion)
	Write-Output "Installed Android Gradle template $templateVersion."
}
