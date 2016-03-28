$scriptName = 'MVC.ps1'
$versionChoices = '3' 
Write-Host
Write-Host "[$scriptName] ---------- start ----------"
$version = $args[1]
if ($version) {
    Write-Host "[$scriptName] version     : $version"
} else {
	$version = '3'
    Write-Host "[$scriptName] version     : $version (default, choices $versionChoices)"
}

$mediaDir = $args[0]
if ($mediaDir) {
    Write-Host "[$scriptName] mediaDir : $mediaDir"
} else {
	$mediaDir = 'C:\vagrant\.provision'
    Write-Host "[$scriptName] mediaDir : $mediaDir (default)"
}

if (!( Test-Path $mediaDir )) {
	Write-Host "[$scriptName] mkdir $mediaDir"
	mkdir $mediaDir
}

switch ($version) {
	3 {
		$file = 'AspNetMVC3Setup.exe'
		$uri = 'https://download.microsoft.com/download/3/4/A/34A8A203-BD4B-44A2-AF8B-CA2CFCB311CC/' + $file
	}
    default {
	    Write-Host "[$scriptName] version not supported, choices are $versionChoices"
    }
}

$installFile = $mediaDir + '\' + $file
Write-Host "[$scriptName] installFile : $installFile"

$logFile = $installDir = [Environment]::GetEnvironmentVariable('TEMP', 'user') + '\' + $file + '.log'
Write-Host "[$scriptName] logFile     : $logFile"

Write-Host
if ( Test-Path $installFile ) {
	Write-Host "[$scriptName] $installFile exists, download not required"
} else {

	$webclient = new-object system.net.webclient
	Write-Host "[$scriptName] $webclient.DownloadFile($uri, $installFile)"
	$webclient.DownloadFile($uri, $installFile)
}

$argList = @(
	"/qn",
	"/l*",
	"webdeploy.log",
	"/i",
	"$installFile"
)

Write-Host "[$scriptName] Start-Process -FilePath msiexec -ArgumentList $argList -PassThru -wait -Verb RunAs"
try {
	$proc = Start-Process -FilePath msiexec -ArgumentList $argList -PassThru -wait -Verb RunAs
} catch {
	Write-Host "[$scriptName] $media Install Exception : $_" -ForegroundColor Red
	exit 200
}

Write-Host "[$scriptName] List installed MVC products"
foreach ($product in $($productList = Get-WmiObject Win32_Product)) {
	if ($product.Name -match 'MVC') {
		$product.Name
	}
}

Write-Host
Write-Host "[$scriptName] ---------- stop ----------"