$scriptName = 'Capabilities.ps1'

Write-Host
Write-Host "[$scriptName] ---------- start ----------"

Write-Host
Write-Host "[$scriptName] List networking"
Write-Host "[$scriptName]   Hostname  : $(hostname)"

if ((gwmi win32_computersystem).partofdomain -eq $true) {
	Write-Host "[$scriptName]   Domain    : $((gwmi win32_computersystem).domain)"
} else {
	Write-Host "[$scriptName]   Workgroup : $((gwmi win32_computersystem).domain)"
}

foreach ($item in Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName .) {
	Write-Host "[$scriptName]          IP : $($item.IPAddress)"
}

Write-Host
Write-Host "[$scriptName] List the Computer architecture, Service Pack and 3rd party software"
Write-Host
$computer = "."
$sOS =Get-WmiObject -class Win32_OperatingSystem -computername $computer
foreach($sProperty in $sOS) {
	write-host "  Caption                 : $($sProperty.Caption)"
	write-host "  Description             : $($sProperty.Description)"
	write-host "  OSArchitecture          : $($sProperty.OSArchitecture)"
	write-host "  ServicePackMajorVersion : $($sProperty.ServicePackMajorVersion)"
}

$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
if (($EditionId -like "*nano*") -or ($EditionId -like "*core*") ) {
	$noGUI = '(no GUI)'
}
write-host "  EditionId               : $EditionId $noGUI"
write-host "  PSVersion.Major         : $($PSVersionTable.PSVersion.Major)"

# Disabled until I can determine why this goes async
#Write-Host
#Write-Host "[$scriptName] List the enabled roles"
#Write-Host
#$tempFile = "$env:temp\tempName.log"
#& dism.exe /online /get-features /format:table | out-file $tempFile -Force      
#$WinFeatures = (Import-CSV -Delim '|' -Path $tempFile -Header Name,state | Where-Object {$_.State -eq "Enabled "}) | Select Name
#Remove-Item -Path $tempFile 
#Write-Host "$WinFeatures"

Write-Host
$versionTest = cmd /c dotnet --version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  dotnet core             : not installed"
} else {
	Write-Host "  dotnet core             : $versionTest"
}

$versionTest = cmd /c choco --version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  Chocolatey              : not installed"
} else {
	Write-Host "  Chocolatey              : $versionTest"
}

$versionTest = cmd /c java -version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  Java                    : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  Java                    : $($array[2])"
}

$versionTest = cmd /c javac -version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  Java Compiler           : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  Java Compiler           : $($array[2])"
}

$versionTest = cmd /c mvn --version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  Maven                   : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  Maven                   : $($array[2])"
}

$versionTest = cmd /c NuGet 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  NuGet                   : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  NuGet                   : $($array[2])"
}

$versionTest = cmd /c 7za.exe i 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  7za.exe                 : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  7za.exe                 : $($array[3])"
}

$versionTest = cmd /c curl.exe --version 2`>`&1
if ($versionTest -like '*not recognized*') {
	Write-Host "  curl.exe                : not installed"
} else {
	$array = $versionTest.split(" ")
	Write-Host "  curl.exe                : $($array[1])"
}

Write-Host
Write-Host "[$scriptName] List the build tools"
$regkey = 'HKLM:\Software\Microsoft\MSBuild\ToolsVersions'
Write-Host
if ( Test-Path $regkey ) { 
	foreach($buildTool in Get-ChildItem $regkey) {
		Write-Host "  $buildTool"
	}
} else {
	Write-Host "  Build tools not found ($regkey)"
}

Write-Host
Write-Host "[$scriptName] List the WIF Installed Versions"
$regkey = 'HKLM:\SOFTWARE\Microsoft\Windows Identity Foundation\setup'
Write-Host
if ( Test-Path $regkey ) { 
	foreach($wif in Get-ChildItem $regkey) {
		Write-Host "  $wif"
	}
} else {
	Write-Host "  Windows Identity Foundation not installed ($regkey)"
}

Write-Host
Write-Host "[$scriptName] List installed MVC products (not applicable after MVC4)"
Write-Host
if (Test-Path 'C:\Program Files (x86)\Microsoft ASP.NET' ) {
	foreach($mvc in Get-ChildItem 'C:\Program Files (x86)\Microsoft ASP.NET') {
		Write-Host "  $mvc"
	}
} else {
	Write-Host "  MVC not explicitely installed (not required for MVC 5 and above)"
}

Write-Host
Write-Host "[$scriptName] List Web Deploy versions installed"
Write-Host
$regkey = 'HKLM:\Software\Microsoft\IIS Extensions\MSDeploy'
if ( Test-Path $regkey ) { 
	foreach($msDeploy in Get-ChildItem $regkey) {
		Write-Host "  $msDeploy"
	}
} else {
	Write-Host "  Web Deploy not installed ($regkey)"
}

Write-Host
Write-Host "[$scriptName] List the .NET Versions"

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release, @{
  name="Product"
  expression={
    switch -regex ($_.Release) {
      "378389" { [Version]"4.5" }
      "378675|378758" { [Version]"4.5.1" }
      "379893" { [Version]"4.5.2" }
      "393295|393297" { [Version]"4.6" }
      "394254|394271" { [Version]"4.6.1" }
      "394802|394806" { [Version]"4.6.2" }
      {$_ -gt 394806} { [Version]"Undocumented 4.6.2 or higher, please update script" }
    }
  }
}

$error.clear()
exit 0
