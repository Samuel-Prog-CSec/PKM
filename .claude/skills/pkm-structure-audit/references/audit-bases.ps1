$root = "C:\Users\Samuel\Documents\PKM"
$rp   = $root + "\"
function Rel($p){ return $p.Replace($rp, "") }

$bases = Get-ChildItem $root -Recurse -Filter *.base -File | Where-Object { $_.FullName -notmatch '\\\.(obsidian|claude|agents|git)' }
$notes = Get-ChildItem $root -Recurse -Filter *.md -File | Where-Object { $_.FullName -notmatch '\\\.(obsidian|claude|agents|git)' }

$baseNames = @{}
foreach($b in $bases){ $baseNames[$b.BaseName] = Rel $b.FullName }

$areaUse = @{}
$areaBad = @()
$noArea  = @()
foreach($n in $notes){
  $line = (Select-String -Path $n.FullName -Pattern '^Area:' -Encoding UTF8 | Select-Object -First 1).Line
  $rel  = Rel $n.FullName
  if(-not $line -or $line -match '^Area:\s*$'){ $noArea += $rel; continue }
  $m = [regex]::Match($line, '\[\[([^\]\|]+?)(\.base)?(\|[^\]]*)?\]\]')
  if(-not $m.Success){ $areaBad += ($rel + "   ->   " + $line); continue }
  $target = $m.Groups[1].Value
  if($baseNames.ContainsKey($target)){
    if($areaUse.ContainsKey($target)){ $areaUse[$target]++ } else { $areaUse[$target] = 1 }
  } else { $areaBad += ($rel + "   ->   " + $line) }
}

$selfMismatch = @()
$orphanBase   = @()
$level1 = @()
foreach($b in $bases){
  $txt = Get-Content $b.FullName -Raw -Encoding UTF8
  if($txt -match 'file\.ext\s*==\s*"base"'){ $level1 += $b.BaseName; continue }
  $m = [regex]::Match($txt, 'Area\s*==\s*link\(\s*"([^"]+?)\.base"')
  if($m.Success -and $m.Groups[1].Value -ne $b.BaseName){
    $selfMismatch += ($b.BaseName + ".base   filtra por ->   " + $m.Groups[1].Value + ".base")
  }
  if(-not $areaUse.ContainsKey($b.BaseName)){ $orphanBase += (Rel $b.FullName) }
}

$okCount = 0; foreach($v in $areaUse.Values){ $okCount += $v }
Write-Output "======== RESUMEN"
Write-Output (".base totales      : " + $bases.Count + "   (Level 0/1: " + $level1.Count + " | Level 2: " + ($bases.Count - $level1.Count) + ")")
Write-Output ("notas totales      : " + $notes.Count)
Write-Output ("notas con Area ok  : " + $okCount)
Write-Output ""
Write-Output ("======== [CRITICO] .base cuyo filtro no coincide con su nombre: " + $selfMismatch.Count)
$selfMismatch | ForEach-Object { Write-Output ("   " + $_) }
Write-Output ""
Write-Output ("======== [CRITICO] Area que no apunta a un .base existente: " + $areaBad.Count)
$areaBad | ForEach-Object { Write-Output ("   " + $_) }
Write-Output ""
Write-Output ("======== [AVISO] .base Level 2 huerfanos (sin notas): " + $orphanBase.Count)
$orphanBase | ForEach-Object { Write-Output ("   " + $_) }
Write-Output ""
Write-Output ("======== [DEUDA] notas sin Area: " + $noArea.Count)
$noArea | ForEach-Object { Write-Output ("   " + $_) }
