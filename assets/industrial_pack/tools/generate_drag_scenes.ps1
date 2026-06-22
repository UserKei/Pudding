param(
	[string]$ExtractedRoot = "",
	[string]$ScenesRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PackRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($ExtractedRoot)) {
	$ExtractedRoot = Join-Path $PackRoot.Path "extracted"
}
if ([string]::IsNullOrWhiteSpace($ScenesRoot)) {
	$ScenesRoot = Join-Path $PackRoot.Path "scenes\extracted"
}

$ExtractedPath = Resolve-Path -LiteralPath $ExtractedRoot
if (-not $ExtractedPath.Path.StartsWith($PackRoot.Path)) {
	throw "Refusing extracted root outside pack root: $($ExtractedPath.Path)"
}

$ScenesParent = Split-Path -Parent $ScenesRoot
if (-not (Test-Path -LiteralPath $ScenesParent)) {
	New-Item -ItemType Directory -Force -Path $ScenesParent | Out-Null
}

if (Test-Path -LiteralPath $ScenesRoot) {
	$ResolvedScenes = Resolve-Path -LiteralPath $ScenesRoot
	if (-not $ResolvedScenes.Path.StartsWith($PackRoot.Path)) {
		throw "Refusing to remove scenes outside pack root: $($ResolvedScenes.Path)"
	}
	if ((Split-Path -Leaf $ResolvedScenes.Path) -ne "extracted") {
		throw "Refusing to remove unexpected scenes directory: $($ResolvedScenes.Path)"
	}
	Remove-Item -LiteralPath $ResolvedScenes.Path -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $ScenesRoot | Out-Null

function Convert-ToGodotPath {
	param([string]$Path)

	$projectRoot = Resolve-Path -LiteralPath (Join-Path $PackRoot.Path "..\..")
	$fullPath = (Resolve-Path -LiteralPath $Path).Path
	if (-not $fullPath.StartsWith($projectRoot.Path)) {
		throw "Path is outside project root: $fullPath"
	}

	$relative = $fullPath.Substring($projectRoot.Path.Length + 1).Replace("\", "/")
	return "res://$relative"
}

function Convert-ToNodeName {
	param([string]$BaseName)

	$parts = $BaseName -split "[^A-Za-z0-9]+"
	$name = ""
	foreach ($part in $parts) {
		if ([string]::IsNullOrWhiteSpace($part)) {
			continue
		}
		$name += $part.Substring(0, 1).ToUpperInvariant() + $part.Substring(1)
	}
	if ([string]::IsNullOrWhiteSpace($name)) {
		return "ExtractedSprite"
	}
	if ($name[0] -match "[0-9]") {
		return "Sprite$name"
	}
	return $name
}

$sets = @("by_cell", "connected_objects")
$entries = New-Object System.Collections.Generic.List[object]

foreach ($setName in $sets) {
	$setPath = Join-Path $ExtractedPath.Path $setName
	if (-not (Test-Path -LiteralPath $setPath)) {
		continue
	}

	Get-ChildItem -LiteralPath $setPath -Recurse -Filter "*.png" -File | Sort-Object FullName | ForEach-Object {
		$relativeToSet = $_.FullName.Substring($setPath.Length + 1)
		$category = Split-Path -Parent $relativeToSet
		if ([string]::IsNullOrWhiteSpace($category)) {
			$category = "uncategorized"
		}
		$sceneDir = Join-Path (Join-Path $ScenesRoot $setName) $category
		New-Item -ItemType Directory -Force -Path $sceneDir | Out-Null

		$sceneName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) + ".tscn"
		$scenePath = Join-Path $sceneDir $sceneName
		$texturePath = Convert-ToGodotPath $_.FullName
		$nodeName = Convert-ToNodeName ([System.IO.Path]::GetFileNameWithoutExtension($_.Name))

		$sceneText = @"
[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="$texturePath" id="1_texture"]

[node name="$nodeName" type="Sprite2D"]
texture_filter = 1
texture = ExtResource("1_texture")
"@

		Set-Content -LiteralPath $scenePath -Value $sceneText -NoNewline

		$entries.Add([pscustomobject]@{
			Set = $setName
			Category = $category.Replace("\", "/")
			Texture = $texturePath
			Scene = Convert-ToGodotPath $scenePath
		}) | Out-Null
	}
}

$manifestPath = Join-Path $ScenesRoot "drag_scene_manifest.csv"
$entries | Sort-Object Set, Category, Texture | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

$indexPath = Join-Path $ScenesRoot "INDEX.md"
$byCellCount = ($entries | Where-Object { $_.Set -eq "by_cell" } | Measure-Object).Count
$objectCount = ($entries | Where-Object { $_.Set -eq "connected_objects" } | Measure-Object).Count
$totalCount = $entries.Count
$indexText = @"
# Industrial Drag Scene Index

Generated drag-ready `Sprite2D` scenes for extracted atlas PNG assets.

- By-cell scenes: $byCellCount
- Connected-object scenes: $objectCount
- Total scenes: $totalCount

Use by_cell scenes when you want exact 16x16 atlas cells. Use connected_objects scenes when you want automatically isolated art objects or animation fragments.

The generated scenes are simple visual prefabs. Add collision, gameplay scripts, or animation controllers only to the subset you promote into actual game props.
"@
Set-Content -LiteralPath $indexPath -Value $indexText -NoNewline

Write-Output "Generated $totalCount drag-ready scenes at $ScenesRoot"
