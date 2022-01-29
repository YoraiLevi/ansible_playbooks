#https://serverfault.com/questions/1018220/how-do-i-install-an-app-from-windows-store-using-powershell

#Usage:
# > Download-AppxPackage "https://www.microsoft.com/en-us/p/dynamic-theme/9nblggh1zbkw" "$ENV:USERPROFILE\Desktop"
# C:\Users\user\Desktop\55888ChristopheLavalle.DynamicTheme_1.4.30233.0_neutral_~_jdggxwd41xcr0.AppxBundle
# C:\Users\user\Desktop\55888ChristopheLavalle.DynamicTheme_1.4.30234.0_neutral_~_jdggxwd41xcr0.AppxBundle
# C:\Users\user\Desktop\Microsoft.NET.Native.Framework.1.7_1.7.27413.0_x64__8wekyb3d8bbwe.Appx
# C:\Users\user\Desktop\Microsoft.NET.Native.Runtime.1.7_1.7.27422.0_x64__8wekyb3d8bbwe.Appx
# C:\Users\user\Desktop\Microsoft.Services.Store.Engagement_10.0.19011.0_x64__8wekyb3d8bbwe.Appx
# C:\Users\user\Desktop\Microsoft.VCLibs.140.00_14.0.29231.0_x64__8wekyb3d8bbwe.Appx
function Resolve-NameConflict {
  #Accepts Path to a FILE and changes it so there are no name conflicts
  param(
    [string]$Path
  )
  $newPath = $Path
  if (Test-Path $Path) {
    $i = 0;
    $item = (Get-Item $Path)
    while (Test-Path $newPath) {
      $i += 1;
      $newPath = Join-Path $item.DirectoryName ($item.BaseName + "($i)" + $item.Extension)
    }
  }
  return $newPath
}
function Select-Zip {
  # https://stackoverflow.com/a/44055098/12603110
  [CmdletBinding()]
  Param(
    $First,
    $Second,
    $ResultSelector = { , $args }
  )

  [System.Linq.Enumerable]::Zip($First, $Second, [Func[Object, Object, Object[]]]$ResultSelector)
}
function Fetch-AppxPackage {
  [CmdletBinding()]
  param (
    [parameter(ValueFromPipeline)][string]$Uri
  )
  process {
    $ErrorActionPreference = 'Stop'
    #Get Urls to download
    $WebResponse = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=url&url=$Uri&ring=Retail" -ContentType 'application/x-www-form-urlencoded'
    $LinksMatch = $WebResponse.Links | Where-Object { $_ -like '*.appx*' -or $_ -like '*.msix*' } | Where-Object { $_ -like '*_neutral_*' -or $_ -like '*_' + $env:PROCESSOR_ARCHITECTURE.Replace('AMD', 'X').Replace('IA', 'X') + '_*' }
    $DownloadLinks = ($LinksMatch  | Select-String -Pattern '(?<=a href=").+(?=" r)').matches.value
    $FileNames = ($LinksMatch  | Select-String -Pattern '(?<=">).+(?=</a>)').Matches.Value
    $LinkFileNameTuple = Select-Zip $DownloadLinks $FileNames
    $template = @'
{name*:VideoLAN.VLC}_{version:2018.802.825.0}_{platform:neutral}_~_{id:paz6r1rewnh0a}.AppxBundle
{name*:VideoLAN.VLC}_{version:3.2.1.0}_{platform:neutral}_~_{id:paz6r1rewnh0a}.AppxBundle
'@
    #Download Urls
    $o = foreach ($tuple in $LinkFileNameTuple) {
      $url = $tuple[0]
      $FileName = $tuple[1]
      $o = $FileName | ConvertFrom-String -TemplateContent $template
      $o | Add-Member -NotePropertyName url -NotePropertyValue $url
      $o | Add-Member -NotePropertyName filename -NotePropertyValue $FileName
      $o
    } 
    $appxBundles = $o | Sort-Object -Property version -Descending -Unique | Group-Object -Property name | ForEach-Object { write-output $_.Group[0] }
    # Write-Host $appxBundles
    return $appxBundles
  }
}
function Download-AppxPackage {
  param (
    [parameter(ValueFromPipeline)]$appxBundles,
    [string]$Path = '.'
  )
  process {
    $ErrorActionPreference = 'Stop'
    $Path = (Resolve-Path $Path).Path
    Write-Host $Path
    foreach ($appxBundle in $appxBundles) {
      Write-Host "Downloading... $($appxBundle.name) version: $($appxBundle.version)" -NoNewline
      $FileRequest = Invoke-WebRequest -Uri $appxBundle.url
      $FileName = $appxBundle.filename #($FileRequest.Headers["Content-Disposition"] | Select-String -Pattern  '(?<=filename=).+').matches.value
      $FilePath = Join-Path $Path $FileName; $FilePath = Resolve-NameConflict($FilePath)
      [System.IO.File]::WriteAllBytes($FilePath, $FileRequest.content)
      Write-Host " Done. See: $FilePath"
      Write-Output $FilePath
    }
  }
}
function Get-AppxPackageInstalled {
  param([parameter(ValueFromPipeline)]$appxBundle)
  process {
    Get-AppxPackage -Name $appxBundle.name
  }
}

function Get-AppxPackagesInstalled {
  param([parameter(ValueFromPipeline)]$appxBundles)
  process {
    $appxBundles | ForEach-Object { Get-AppxPackageInstalled -appxBundle $_ }
  }
}

function Get-AppxPackagesNotInstalled {
  param ([parameter(ValueFromPipeline)]$appxBundles)
  process {
    return $appxBundles | ForEach-Object { if (-not (Get-AppxPackageInstalled -appxBundle $_)) { $_ } }
  }
}

function Get-LatestAppxPackages {
  param ([parameter(ValueFromPipeline)]$appxBundles)
  process {
    return $appxBundles | Sort-Object -Property version -Descending -Unique | Sort-Object -Property name -unique
  }
  
}
# function Sort-AppxPackagesDependencies {
#   param ([parameter(ValueFromPipeline)]$appxBundles)
#   end {
#     # .AppxBundles may rely on .Appx, sort by extension name
#     return $appxBundles | foreach { [PSCustomObject]@{ext = [System.IO.Path]::GetExtension($_); path = $_ }; } | sort | foreach { $_.path }
#   }
# }
function Install-AppxPackageFromStoreUrl {
  param (
    [parameter(ValueFromPipeline)][string]$Uri,
    [string]$TempDir = "$env:Temp"
  )
  Fetch-AppxPackage -Uri $Uri | Get-LatestAppxPackages | Get-AppxPackagesNotInstalled | Download-AppxPackage -Path $TempDir | ForEach-Object { [PSCustomObject]@{ext = [System.IO.Path]::GetExtension($_); path = $_ }; } | Sort-Object -Property ext | ForEach-Object { $_.path } | ForEach-Object { Write-Output "Installing $_"; Add-AppxPackage -Path $_ -DeferRegistrationWhenPackagesAreInUse }
}