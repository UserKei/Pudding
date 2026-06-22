param(
	[string]$Source = "",
	[string]$OutputRoot = "",
	[int]$TileSize = 16
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$PackRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($Source)) {
	$Source = Join-Path $PackRoot.Path "art\industrial.png"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
	$OutputRoot = Join-Path $PackRoot.Path "extracted"
}

$SourcePath = Resolve-Path -LiteralPath $Source
$OutputParent = Split-Path -Parent $OutputRoot
if (-not (Test-Path -LiteralPath $OutputParent)) {
	New-Item -ItemType Directory -Force -Path $OutputParent | Out-Null
}

if (Test-Path -LiteralPath $OutputRoot) {
	$ResolvedOutput = Resolve-Path -LiteralPath $OutputRoot
	if (-not $ResolvedOutput.Path.StartsWith($PackRoot.Path)) {
		throw "Refusing to remove output outside pack root: $($ResolvedOutput.Path)"
	}
	if ((Split-Path -Leaf $ResolvedOutput.Path) -ne "extracted") {
		throw "Refusing to remove unexpected output directory: $($ResolvedOutput.Path)"
	}
	Remove-Item -LiteralPath $ResolvedOutput.Path -Recurse -Force
}

New-Item -ItemType Directory -Force -Path `
	(Join-Path $OutputRoot "by_cell"), `
	(Join-Path $OutputRoot "connected_objects"), `
	(Join-Path $OutputRoot "contact_sheets"), `
	(Join-Path $OutputRoot "manifests") | Out-Null

function Get-IndustrialCategory {
	param(
		[int]$X,
		[int]$Y,
		[int]$Width,
		[int]$Height,
		[int]$PixelCount,
		[bool]$HasHotPink
	)

	$cx = $X + ($Width / 2.0)
	$cy = $Y + ($Height / 2.0)

	if ($cy -lt 64) { return "architecture_tiles" }
	if ($cy -ge 64 -and $cy -lt 128 -and $cx -lt 128) { return "architecture_blocks" }
	if ($cy -ge 64 -and $cy -lt 128 -and $cx -ge 128 -and $cx -lt 336) { return "pipes_machinery" }
	if ($cy -ge 64 -and $cy -lt 128 -and $cx -ge 336 -and $cx -lt 448) { return "machinery_structures" }
	if ($cy -ge 128 -and $cy -lt 192 -and $cx -lt 80) { return "floor_wall_blocks" }
	if ($cy -ge 128 -and $cy -lt 192 -and $cx -ge 80 -and $cx -lt 192) { return "lights_collectibles" }
	if ($cy -ge 128 -and $cy -lt 240 -and $cx -ge 192 -and $cx -lt 336) { return "pipes_machinery" }
	if ($cy -ge 128 -and $cy -lt 192 -and $cx -ge 336 -and $cx -lt 464) { return "buttons_lights" }
	if ($cy -ge 192 -and $cy -lt 256 -and $HasHotPink) { return "hazards_markers" }
	if ($cy -ge 192 -and $cy -lt 256 -and $cx -lt 96) { return "architecture_blocks" }
	if ($cy -ge 192 -and $cy -lt 256 -and $cx -ge 96 -and $cx -lt 192) { return "hazards_markers" }
	if ($cy -ge 192 -and $cy -lt 256 -and $cx -ge 192 -and $cx -lt 336) { return "pipes_machinery" }
	if ($cy -ge 192 -and $cy -lt 256 -and $cx -ge 336) { return "decor_structures" }
	if ($cy -ge 256 -and $cy -lt 320 -and $cx -lt 128) { return "player_character_frames" }
	if ($cy -ge 256 -and $cy -lt 336 -and $cx -ge 128 -and $cx -lt 240) { return "projectiles_fx_symbols" }
	if ($cy -ge 320 -and $cy -lt 448 -and $cx -lt 160) { return "npc_machine_frames" }
	if ($cy -ge 320 -and $cy -lt 352 -and $cx -ge 160 -and $cx -lt 240) { return "ui_symbols" }
	if ($cy -ge 384 -and $cy -lt 448 -and $cx -lt 192) { return "machines_terminals" }
	if ($HasHotPink) { return "hazards_markers" }

	return "misc"
}

function Test-HotPink {
	param([System.Collections.Generic.List[int]]$Pixels, [System.Drawing.Bitmap]$Image, [int]$ImageWidth)

	foreach ($packed in $Pixels) {
		$px = $packed % $ImageWidth
		$py = [Math]::Floor($packed / $ImageWidth)
		$c = $Image.GetPixel($px, $py)
		if ($c.R -ge 190 -and $c.G -le 110 -and $c.B -ge 100) {
			return $true
		}
	}
	return $false
}

function Test-HotPinkRect {
	param([System.Drawing.Bitmap]$Image, [int]$X, [int]$Y, [int]$Width, [int]$Height)

	for ($yy = $Y; $yy -lt ($Y + $Height); $yy++) {
		for ($xx = $X; $xx -lt ($X + $Width); $xx++) {
			$c = $Image.GetPixel($xx, $yy)
			if ($c.A -gt 0 -and $c.R -ge 190 -and $c.G -le 110 -and $c.B -ge 100) {
				return $true
			}
		}
	}
	return $false
}

function Save-CellCrop {
	param(
		[System.Drawing.Bitmap]$Image,
		[int]$X,
		[int]$Y,
		[int]$Width,
		[int]$Height,
		[string]$Path
	)

	$out = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($out)
	$g.Clear([System.Drawing.Color]::Transparent)
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	$srcRect = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
	$dstRect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
	$g.DrawImage($Image, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
	$g.Dispose()
	$out.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$out.Dispose()
}

function Save-ComponentCrop {
	param(
		[System.Drawing.Bitmap]$Image,
		[System.Collections.Generic.List[int]]$Pixels,
		[int]$ImageWidth,
		[int]$MinX,
		[int]$MinY,
		[int]$Width,
		[int]$Height,
		[string]$Path
	)

	$out = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	foreach ($packed in $Pixels) {
		$px = $packed % $ImageWidth
		$py = [Math]::Floor($packed / $ImageWidth)
		$out.SetPixel($px - $MinX, $py - $MinY, $Image.GetPixel($px, $py))
	}
	$out.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$out.Dispose()
}

function New-ContactSheet {
	param(
		[array]$Items,
		[string]$Path,
		[int]$ThumbSize = 48,
		[int]$Columns = 12
	)

	if ($Items.Count -eq 0) {
		return
	}

	$rows = [Math]::Ceiling($Items.Count / [double]$Columns)
	$sheet = [System.Drawing.Bitmap]::new($Columns * $ThumbSize, [int]$rows * $ThumbSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($sheet)
	$g.Clear([System.Drawing.Color]::FromArgb(255, 16, 16, 20))
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

	for ($i = 0; $i -lt $Items.Count; $i++) {
		$item = $Items[$i]
		$img = [System.Drawing.Bitmap]::FromFile((Join-Path $OutputRoot $item.relative_file))
		$scale = [Math]::Min(($ThumbSize - 8) / [double]$img.Width, ($ThumbSize - 8) / [double]$img.Height)
		$dw = [Math]::Max(1, [int][Math]::Floor($img.Width * $scale))
		$dh = [Math]::Max(1, [int][Math]::Floor($img.Height * $scale))
		$dx = (($i % $Columns) * $ThumbSize) + [int][Math]::Floor(($ThumbSize - $dw) / 2)
		$dy = ([int][Math]::Floor($i / $Columns) * $ThumbSize) + [int][Math]::Floor(($ThumbSize - $dh) / 2)
		$g.DrawImage($img, $dx, $dy, $dw, $dh)
		$img.Dispose()
	}

	$g.Dispose()
	$sheet.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$sheet.Dispose()
}

$Image = [System.Drawing.Bitmap]::FromFile($SourcePath.Path)
$Width = $Image.Width
$Height = $Image.Height
$Visible = [bool[,]]::new($Width, $Height)
$Visited = [bool[,]]::new($Width, $Height)
$TotalVisiblePixels = 0

for ($y = 0; $y -lt $Height; $y++) {
	for ($x = 0; $x -lt $Width; $x++) {
		$c = $Image.GetPixel($x, $y)
		if ($c.A -gt 0) {
			$Visible[$x, $y] = $true
			$TotalVisiblePixels++
		}
	}
}

$Entries = [System.Collections.Generic.List[object]]::new()
$CategoryCounts = @{}
$CellCoveredPixels = 0
$CellCount = 0

for ($tileY = 0; $tileY -lt $Height; $tileY += $TileSize) {
	for ($tileX = 0; $tileX -lt $Width; $tileX += $TileSize) {
		$tileWidth = [Math]::Min($TileSize, $Width - $tileX)
		$tileHeight = [Math]::Min($TileSize, $Height - $tileY)
		$visibleCount = 0
		for ($yy = $tileY; $yy -lt ($tileY + $tileHeight); $yy++) {
			for ($xx = $tileX; $xx -lt ($tileX + $tileWidth); $xx++) {
				if ($Visible[$xx, $yy]) {
					$visibleCount++
				}
			}
		}

		if ($visibleCount -eq 0) {
			continue
		}

		$hasHotPink = Test-HotPinkRect -Image $Image -X $tileX -Y $tileY -Width $tileWidth -Height $tileHeight
		$category = Get-IndustrialCategory -X $tileX -Y $tileY -Width $tileWidth -Height $tileHeight -PixelCount $visibleCount -HasHotPink $hasHotPink
		$categoryDir = Join-Path (Join-Path $OutputRoot "by_cell") $category
		New-Item -ItemType Directory -Force -Path $categoryDir | Out-Null

		$row = [int]($tileY / $TileSize)
		$col = [int]($tileX / $TileSize)
		$id = "cell_r{0:D2}_c{1:D2}_x{2}_y{3}" -f $row, $col, $tileX, $tileY
		$fileName = "$id.png"
		$filePath = Join-Path $categoryDir $fileName
		Save-CellCrop -Image $Image -X $tileX -Y $tileY -Width $tileWidth -Height $tileHeight -Path $filePath

		$relativeFile = "by_cell/$category/$fileName"
		$Entries.Add([PSCustomObject][ordered]@{
			id = $id
			set = "by_cell"
			category = $category
			relative_file = $relativeFile
			source_rect = [ordered]@{ x = $tileX; y = $tileY; width = $tileWidth; height = $tileHeight }
			grid = [ordered]@{ row = $row; column = $col; tile_size = $TileSize }
			visible_pixels = $visibleCount
			has_hot_pink = $hasHotPink
		}) | Out-Null

		$CellCoveredPixels += $visibleCount
		$CellCount++
		$CategoryCounts[$category] = 1 + [int]($CategoryCounts[$category])
	}
}

$ComponentCoveragePixels = 0
$ComponentCount = 0
$Queue = [int[]]::new($Width * $Height)
$Directions = @(
	@(-1, -1), @(0, -1), @(1, -1),
	@(-1, 0),           @(1, 0),
	@(-1, 1),  @(0, 1), @(1, 1)
)

for ($startY = 0; $startY -lt $Height; $startY++) {
	for ($startX = 0; $startX -lt $Width; $startX++) {
		if (-not $Visible[$startX, $startY] -or $Visited[$startX, $startY]) {
			continue
		}

		$pixels = [System.Collections.Generic.List[int]]::new()
		$head = 0
		$tail = 0
		$startPacked = $startY * $Width + $startX
		$Queue[$tail] = $startPacked
		$tail++
		$Visited[$startX, $startY] = $true
		$minX = $startX
		$maxX = $startX
		$minY = $startY
		$maxY = $startY

		while ($head -lt $tail) {
			$packed = $Queue[$head]
			$head++
			$pixels.Add($packed) | Out-Null
			$x = $packed % $Width
			$y = [Math]::Floor($packed / $Width)

			if ($x -lt $minX) { $minX = $x }
			if ($x -gt $maxX) { $maxX = $x }
			if ($y -lt $minY) { $minY = $y }
			if ($y -gt $maxY) { $maxY = $y }

			foreach ($dir in $Directions) {
				$nx = $x + $dir[0]
				$ny = $y + $dir[1]
				if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $Width -or $ny -ge $Height) {
					continue
				}
				if ($Visible[$nx, $ny] -and -not $Visited[$nx, $ny]) {
					$Visited[$nx, $ny] = $true
					$Queue[$tail] = $ny * $Width + $nx
					$tail++
				}
			}
		}

		$componentWidth = $maxX - $minX + 1
		$componentHeight = $maxY - $minY + 1
		$hasComponentHotPink = Test-HotPink -Pixels $pixels -Image $Image -ImageWidth $Width
		$category = Get-IndustrialCategory -X $minX -Y $minY -Width $componentWidth -Height $componentHeight -PixelCount $pixels.Count -HasHotPink $hasComponentHotPink
		$categoryDir = Join-Path (Join-Path $OutputRoot "connected_objects") $category
		New-Item -ItemType Directory -Force -Path $categoryDir | Out-Null

		$ComponentCount++
		$id = "object_{0:D4}_x{1}_y{2}_w{3}_h{4}" -f $ComponentCount, $minX, $minY, $componentWidth, $componentHeight
		$fileName = "$id.png"
		$filePath = Join-Path $categoryDir $fileName
		Save-ComponentCrop -Image $Image -Pixels $pixels -ImageWidth $Width -MinX $minX -MinY $minY -Width $componentWidth -Height $componentHeight -Path $filePath

		$relativeFile = "connected_objects/$category/$fileName"
		$Entries.Add([PSCustomObject][ordered]@{
			id = $id
			set = "connected_objects"
			category = $category
			relative_file = $relativeFile
			source_rect = [ordered]@{ x = $minX; y = $minY; width = $componentWidth; height = $componentHeight }
			visible_pixels = $pixels.Count
			has_hot_pink = $hasComponentHotPink
		}) | Out-Null

		$ComponentCoveragePixels += $pixels.Count
		$CategoryCounts[$category] = 1 + [int]($CategoryCounts[$category])
	}
}

$GroupedEntries = $Entries | Group-Object -Property set, category
foreach ($group in $GroupedEntries) {
	$first = $group.Group[0]
	$sheetName = "{0}_{1}.png" -f $first.set, $first.category
	New-ContactSheet -Items $group.Group -Path (Join-Path (Join-Path $OutputRoot "contact_sheets") $sheetName)
}

$CategorySummary = [ordered]@{}
foreach ($category in ($Entries | Select-Object -ExpandProperty category -Unique | Sort-Object)) {
	$CategorySummary[$category] = [ordered]@{
		by_cell = @($Entries | Where-Object { $_.category -eq $category -and $_.set -eq "by_cell" }).Count
		connected_objects = @($Entries | Where-Object { $_.category -eq $category -and $_.set -eq "connected_objects" }).Count
	}
}

$Manifest = [ordered]@{
	generated_at = (Get-Date).ToString("o")
	source_file = "res://assets/industrial_pack/art/industrial.png"
	atlas_size = [ordered]@{ width = $Width; height = $Height }
	tile_size = $TileSize
	strategy = [ordered]@{
		by_cell = "Every non-empty ${TileSize}x${TileSize} atlas cell is exported as a standalone PNG."
		connected_objects = "Every alpha-visible 8-neighbor connected component is exported as a standalone PNG with transparent background."
	}
	counts = [ordered]@{
		visible_pixels = $TotalVisiblePixels
		by_cell_assets = $CellCount
		connected_object_assets = $ComponentCount
		total_entries = $Entries.Count
		categories = $CategorySummary
	}
	coverage = [ordered]@{
		by_cell_visible_pixels_covered = $CellCoveredPixels
		by_cell_complete = ($CellCoveredPixels -eq $TotalVisiblePixels)
		connected_visible_pixels_covered = $ComponentCoveragePixels
		connected_complete = ($ComponentCoveragePixels -eq $TotalVisiblePixels)
	}
	entries = $Entries
}

$ManifestPath = Join-Path (Join-Path $OutputRoot "manifests") "industrial_extraction_manifest.json"
$Manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
$Entries | Export-Csv -LiteralPath (Join-Path (Join-Path $OutputRoot "manifests") "industrial_extraction_manifest.csv") -NoTypeInformation -Encoding UTF8

$IndexLines = [System.Collections.Generic.List[string]]::new()
$IndexLines.Add("# Industrial Atlas Extraction Index") | Out-Null
$IndexLines.Add("") | Out-Null
$IndexLines.Add("- Source: res://assets/industrial_pack/art/industrial.png") | Out-Null
$IndexLines.Add("- Visible pixels: $TotalVisiblePixels") | Out-Null
$IndexLines.Add("- By-cell assets: $CellCount") | Out-Null
$IndexLines.Add("- Connected-object assets: $ComponentCount") | Out-Null
$IndexLines.Add("- By-cell coverage complete: $($CellCoveredPixels -eq $TotalVisiblePixels)") | Out-Null
$IndexLines.Add("- Connected-object coverage complete: $($ComponentCoveragePixels -eq $TotalVisiblePixels)") | Out-Null
$IndexLines.Add("") | Out-Null
$IndexLines.Add("## Categories") | Out-Null
foreach ($category in $CategorySummary.Keys) {
	$summary = $CategorySummary[$category]
	$IndexLines.Add("- " + $category + ": by-cell " + $summary.by_cell + ", connected " + $summary.connected_objects) | Out-Null
}
$IndexLines.Add("") | Out-Null
$IndexLines.Add("Generated PNGs live under by_cell/<category>/ and connected_objects/<category>/. Contact sheets live under contact_sheets/.") | Out-Null
$IndexLines | Set-Content -LiteralPath (Join-Path $OutputRoot "INDEX.md") -Encoding UTF8

$Image.Dispose()

Write-Output "Extracted $CellCount non-empty atlas cells and $ComponentCount connected objects."
Write-Output "Visible pixels: $TotalVisiblePixels"
Write-Output "By-cell coverage: $CellCoveredPixels"
Write-Output "Connected-object coverage: $ComponentCoveragePixels"
Write-Output "Manifest: $ManifestPath"
