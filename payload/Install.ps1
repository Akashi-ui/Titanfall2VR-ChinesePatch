param(
 [ValidateSet('Install','Restore')][string]$Action='Install',
 [string]$GameRoot='C:\Program Files\EA Games\Titanfall2'
)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
try {
 if(Get-Process Titanfall2,Titanfall2VRLauncher -ErrorAction SilentlyContinue){throw '在安装或修复《泰坦陨落 2》之前，请先将其关闭。'}
 $gamePath=(Resolve-Path -LiteralPath $GameRoot).Path
 if(-not(Test-Path -LiteralPath (Join-Path $gamePath 'Titanfall2VRLauncher.exe'))){throw '请先安装 VR 模组。'}
 $record=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $gamePath '.circuitlord-vr-mods\Titanfall2VR.json') | ConvertFrom-Json
 $profileRoot=(Resolve-Path -LiteralPath (Join-Path $gamePath 'TF2VR')).Path
 $modPath=[IO.Path]::GetFullPath((Join-Path $profileRoot 'mods\Chinese.MenuTest'))
 $pluginPath=[IO.Path]::GetFullPath((Join-Path $profileRoot 'plugins\Chinese.CaptionLayout.dll'))
 $startupPath=Join-Path $profileRoot 'mods\Titanfall2VR.Cockpit\mod\resource\tf2vr\startup\text.r8'
 $startupOriginal=Join-Path $profileRoot 'chinese-menu-backups\startup-text-original.r8'
 $startupManifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'VRStartup\manifest.json')|ConvertFrom-Json
 $startupHash=if(Test-Path -LiteralPath $startupPath){(Get-FileHash -LiteralPath $startupPath -Algorithm SHA256).Hash}else{''}
 $validBackup=(Test-Path -LiteralPath $startupOriginal) -and ((Get-FileHash -LiteralPath $startupOriginal -Algorithm SHA256).Hash -eq $startupManifest.original_sha256)
 $replaceStartup=($Action -eq 'Install' -and $startupHash -eq $startupManifest.original_sha256) -or ($startupHash -eq $startupManifest.translated_sha256 -and $validBackup)
 if(-not $replaceStartup){Write-Output '启动教程保留了当前 VR 模式下的文件。'}
 foreach($target in @($modPath,$pluginPath)){if(-not $target.StartsWith($profileRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw '目标安装路径不正确'}}
 if(Test-Path -LiteralPath $modPath){$existing=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $modPath 'mod.json')|ConvertFrom-Json;if($existing.Name -ne 'Chinese.MenuTest'){throw '安装位置存在另一个模组。'}}
 $stage=$null
 if($Action -eq 'Install') {
  $inventory=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'package-hashes.json')|ConvertFrom-Json
  foreach($entry in $inventory.PSObject.Properties){
   $source=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot $entry.Name))
   if(-not $source.StartsWith($PSScriptRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw '安装文件路径不正确。'}
   if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $entry.Value){throw ('安装文件验证失败: '+$entry.Name)}
  }
  $sourceManifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'Chinese.MenuTest\mod.json')|ConvertFrom-Json
  if($sourceManifest.Name -ne 'Chinese.MenuTest'){throw '翻译补丁的相关信息不正确'}
  $stage=Join-Path $profileRoot ('chinese-menu-staging-'+[Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $stage | Out-Null
  $integration=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'integration-baseline.json')|ConvertFrom-Json
  function MatchesBaseline($path,$hash){return (Test-Path -LiteralPath $path) -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $hash}
  $northstarKnown=MatchesBaseline (Join-Path $profileRoot 'Northstar.dll') $integration.'Northstar.dll'
  $vrKnown=MatchesBaseline (Join-Path $profileRoot 'plugins/Titanfall2VR.dll') $integration.'plugins/Titanfall2VR.dll'
  foreach($knownHash in @($integration.compatibleVrDllHashes)){
   if($knownHash -and (MatchesBaseline (Join-Path $profileRoot 'plugins/Titanfall2VR.dll') $knownHash)){$vrKnown=$true}
  }
  $menuKnown=$northstarKnown -and $vrKnown
  foreach($rel in @('scripts/vscripts/tf2vr_menu.nut','resource/ui/menus/ingame_sp.menu')){
   if(-not(MatchesBaseline (Join-Path $profileRoot ('mods/Titanfall2VR.Cockpit/mod/'+$rel)) $integration.cockpit.$rel)){$menuKnown=$false}
  }
  $skipped=@()
  $sourceMod=Join-Path $PSScriptRoot 'Chinese.MenuTest'
  $stagedMod=Join-Path $stage 'Chinese.MenuTest'
  foreach($file in Get-ChildItem -LiteralPath $sourceMod -Recurse -File){
   $copySource=$file.FullName
   $rel=$file.FullName.Substring($sourceMod.Length+1).Replace('\','/')
   if(($rel.StartsWith('mod/scripts/') -and $rel -ne 'mod/scripts/vscripts/chinese_menu_test.nut') -or $rel.StartsWith('mod/resource/ui/')){
    $upstreamRel=$rel.Substring(4)
    $upstream=Join-Path $profileRoot ('mods/Titanfall2VR.Cockpit/mod/'+$upstreamRel)
    $entry=$integration.cockpit.PSObject.Properties[$upstreamRel]
    $keep=$northstarKnown
    if($entry){$keep=$keep -and (MatchesBaseline $upstream $entry.Value)}
    elseif(Test-Path -LiteralPath $upstream){$keep=$false}
    if(-not $keep -and $northstarKnown -and $integration.compatibleFileVariants){
     $variants=$integration.compatibleFileVariants.PSObject.Properties[$upstreamRel]
     if($variants){foreach($variant in $variants.Value){
      if(MatchesBaseline $upstream $variant.sha256){$copySource=Join-Path $PSScriptRoot $variant.source;$keep=$true;break}
     }}
    }
    if($upstreamRel -in @('scripts/vscripts/tf2vr_menu.nut','resource/ui/menus/ingame_sp.menu')){$keep=$keep -and $menuKnown}
    if(-not $keep){$skipped+=$rel;continue}
   }
   $destination=Join-Path $stagedMod $rel
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination)|Out-Null
   Copy-Item -LiteralPath $copySource -Destination $destination
  }
  if($northstarKnown){Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Chinese.CaptionLayout.dll') -Destination $stage}
  Write-Output ('변경된 원본으로 인해 제외한 번역 파일: '+$skipped.Count)
  foreach($rel in $skipped){Write-Output ('  '+$rel)}
 }
 $backup=Join-Path $profileRoot ('chinese-menu-backups\v0229-'+[Guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $backup -Force | Out-Null
 if($replaceStartup){Copy-Item -LiteralPath $startupPath -Destination (Join-Path $backup 'startup-text-before.r8')}
 if($replaceStartup -and $startupHash -eq $startupManifest.original_sha256){
  if(Test-Path -LiteralPath $startupOriginal){Copy-Item -LiteralPath $startupOriginal -Destination (Join-Path $backup 'previous-startup-backup.r8')}
  Copy-Item -LiteralPath $startupPath -Destination $startupOriginal -Force
 }
 $enabledPath=Join-Path $profileRoot 'enabledmods.json'
 if(Test-Path -LiteralPath $enabledPath){Copy-Item -LiteralPath $enabledPath -Destination $backup}
 $modMoved=$false;$pluginMoved=$false;$newMod=$false;$newPlugin=$false;$startupChanged=$false
 try {
  if(Test-Path -LiteralPath $modPath){[IO.Directory]::Move($modPath,(Join-Path $backup 'Chinese.MenuTest'));$modMoved=$true}
  if(Test-Path -LiteralPath $pluginPath){[IO.File]::Move($pluginPath,(Join-Path $backup 'Chinese.CaptionLayout.dll'));$pluginMoved=$true}
  if($Action -eq 'Install'){
   New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pluginPath)|Out-Null
   [IO.Directory]::Move((Join-Path $stage 'Chinese.MenuTest'),$modPath);$newMod=$true
   if($northstarKnown){[IO.File]::Move((Join-Path $stage 'Chinese.CaptionLayout.dll'),$pluginPath);$newPlugin=$true}
   if(Test-Path -LiteralPath $enabledPath){
    $enabled=Get-Content -Raw -Encoding UTF8 -LiteralPath $enabledPath|ConvertFrom-Json
    if(-not $enabled.PSObject.Properties['Chinese.MenuTest']){$enabled|Add-Member -NotePropertyName 'Chinese.MenuTest' -NotePropertyValue ([PSCustomObject]@{})}
    $enabled.'Chinese.MenuTest'|Add-Member -NotePropertyName $sourceManifest.Version -NotePropertyValue $true -Force
    [IO.File]::WriteAllText($enabledPath,($enabled|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
   }
  }
  if($replaceStartup){
  $startupChanged=$true
  if($Action -eq 'Install'){$startupSource=Join-Path $PSScriptRoot 'VRStartup\text.r8';$expectedStartup=$startupManifest.translated_sha256}
  else {$startupSource=$startupOriginal;$expectedStartup=$startupManifest.original_sha256}
  Copy-Item -LiteralPath $startupSource -Destination $startupPath -Force
  if((Get-FileHash -LiteralPath $startupPath -Algorithm SHA256).Hash -ne $expectedStartup){throw 'VR 启动程序？验证失败。'}
  }
 } catch {
  if($startupChanged){Copy-Item -LiteralPath (Join-Path $backup 'startup-text-before.r8') -Destination $startupPath -Force}
  if($newMod){[IO.Directory]::Move($modPath,(Join-Path $stage 'Chinese.MenuTest'))}
  if($newPlugin){[IO.File]::Move($pluginPath,(Join-Path $stage 'Chinese.CaptionLayout.dll'))}
  if($modMoved){[IO.Directory]::Move((Join-Path $backup 'Chinese.MenuTest'),$modPath)}
  if($pluginMoved){[IO.File]::Move((Join-Path $backup 'Chinese.CaptionLayout.dll'),$pluginPath)}
  if(Test-Path -LiteralPath (Join-Path $backup 'enabledmods.json')){Copy-Item -LiteralPath (Join-Path $backup 'enabledmods.json') -Destination $enabledPath -Force}
  throw
 }
 Write-Output ('用于备份现有文件的位置: '+$backup)
 if($Action -eq 'Install'){Write-Output '中文补丁已安装。请通过 VR 模组的安装程序启动游戏。'}
 else {Write-Output '已移除补丁，仅将能够确认的启动引导内容恢复为原始版本。'}
}catch{Write-Host $_.Exception.Message -ForegroundColor Red;exit 1}
