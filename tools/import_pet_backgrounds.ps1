param([Parameter(Mandatory = $true)][string]$SourceDirectory)
$ErrorActionPreference = 'Stop'
$targetDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\pet_battles'
$names = @('bg haiwan fight rumah.png', 'bg haiwan fight pantai.jpg', 'bg haiwan fight.jpg', 'bg haiwan fight universe.webp', 'bg haiwan fight.gif')
foreach ($name in $names) {
	if (-not (Test-Path -LiteralPath (Join-Path $SourceDirectory $name) -PathType Leaf)) {
		throw "Missing background: $name"
	}
}
New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
foreach ($name in $names) {
	$source = [IO.Path]::GetFullPath((Join-Path $SourceDirectory $name))
	$destination = [IO.Path]::GetFullPath((Join-Path $targetDirectory $name))
	if ($source -ne $destination) { Copy-Item -LiteralPath $source -Destination $destination }
}
# Godot does not import GIFs as Texture2D. Preserve the original and extract
# its first frame losslessly as PNG, without changing any supplied artwork.
Add-Type -AssemblyName System.Drawing
$image = [Drawing.Image]::FromFile((Join-Path $targetDirectory 'bg haiwan fight.gif'))
try {
	$image.SelectActiveFrame([Drawing.Imaging.FrameDimension]::Time, 0) | Out-Null
	$image.Save((Join-Path $targetDirectory 'bg haiwan fight.png'), [Drawing.Imaging.ImageFormat]::Png)
} finally { $image.Dispose() }
Write-Output 'Five pet battle backgrounds imported. Re-import the Godot project before running.'
