function exitWithCode($taskName) {
    write-host
    write-host "[$scriptName] Caught an exception excuting $taskName :" -ForegroundColor Red
    write-host "     Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "     Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    write-host
    write-host "     Returning errorlevel (-1) to DOS" -ForegroundColor Magenta
    write-host
    $host.SetShouldExit(-1)
    exit
}

function taskComplete { 
    write-host
    write-host "[$scriptName] Remote Task ($taskName) Successfull " -ForegroundColor Green
    write-host
}

function taskWarning($taskName) { 
    write-host
    write-host "[$scriptName] Warning, $taskName encountered an error that was allowed to proceed." -ForegroundColor Yellow
}

function itemRemove ($itemPath) { 
# If item exists, and is a directory, recursively remove hidden and read-only attributes or to explicit file name if just a file 
	if ( Test-Path $itemPath ) {
		if ( (Get-Item $itemPath) -is [System.IO.DirectoryInfo] ) {
			attrib -r -h *.* /s /d
		} else {
			attrib -r -h $itemPath /s
		}	
		write-host "[$scriptName] Delete $itemPath"
		Remove-Item $itemPath -Recurse
		if(!$?) {exitWithCode "Remove-Item $itemPath -Recurse" }
	}
}

function getFilename ($FullPathName) {

	$PIECES=$FullPathName.split(�\�) 
	$NUMBEROFPIECES=$PIECES.Count 
	$FILENAME=$PIECES[$NumberOfPieces-1] 
	$DIRECTORYPATH=$FullPathName.Trim($FILENAME) 
	return $FILENAME

}

function pathTest ($pathToTest) { 
	if ( Test-Path $pathToTest ) {
		Write-Host "found ($pathToTest)"
	} else {
		Write-Host "none ($pathToTest)"
	}
}

function copyDir ($sourceDir, $targetDir, $flat) {
	Write-Host
	if (-not ($flat)) {
		$dirName = getFilename($sourceDir)
		Write-Host "[$scriptName] mkdir $targetDir\$dirName" 
		New-Item $targetDir\$dirName -type directory > $null
	}
	if(!$?){ taskFailure ("mkdir $targetDir\$dirName") }
	foreach ($item in (Get-ChildItem -Path $sourceDir)) {
		if ($flat) {
			copySet $item $sourceDir $targetDir
		} else {
			copySet $item $sourceDir $targetDir\$dirName
		}
	}
}

function copySet ($item, $from, $to) {

	Write-Host "[$scriptName]   $from\$item --> $to" 
	Copy-Item $from\$item $to -Force
	if(!$?){ taskFailure ("Copy remote script $from\$item --> $to") }
	Set-ItemProperty $to\$item -name IsReadOnly -value $false
	if(!$?){ taskFailure ("remove read only from $to\$item") }
	
}

function ZipFiles( $zipfilename, $sourcedir )
{
	try {
		Add-Type -Assembly System.IO.Compression.FileSystem
	} catch {
		taskFailure "Failed to load Compression assembly, is .NET 4.5 or above installed?"
	}
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	Write-Host
	Write-Host "[$scriptName] Create zip package $zipfilename from $sourcedir"
	[System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir, $zipfilename, $compressionLevel, $false)
	foreach ($item in (Get-ChildItem -Path $sourcedir)) {
		Write-Host "[$scriptName]   --> $item"
	}
	
}

$scriptName = $MyInvocation.MyCommand.Name
Write-Host
Write-Host "[$scriptName] +-----------------+"
Write-Host "[$scriptName] | Package Process |"
Write-Host "[$scriptName] +-----------------+"

$SOLUTION = $args[0]
if (-not($SOLUTION)) {exitWithCode SOLUTION_NOT_PASSED }
Write-Host "[$scriptName]   SOLUTION                : $SOLUTION"

$BUILDNUMBER = $args[1]
if (-not($BUILDNUMBER)) {exitWithCode BUILDNUMBER_NOT_PASSED }
Write-Host "[$scriptName]   BUILDNUMBER             : $BUILDNUMBER"

$REVISION = $args[2]
if (-not($REVISION)) {exitWithCode REVISION_NOT_PASSED }
Write-Host "[$scriptName]   REVISION                : $REVISION"

$AUTOMATIONROOT=$args[3]
if (-not($LOCAL_WORK_DIR)) {exitWithCode AUTOMATIONROOT_NOT_PASSED }
Write-Host "[$scriptName]   AUTOMATIONROOT          : $AUTOMATIONROOT"

$SOLUTIONROOT=$args[4]
if (-not($LOCAL_WORK_DIR)) {exitWithCode SOLUTIONROOT_NOT_PASSED }
Write-Host "[$scriptName]   SOLUTIONROOT            : $SOLUTIONROOT"

$LOCAL_WORK_DIR = $args[5]
if (-not($LOCAL_WORK_DIR)) {exitWithCode LOCAL_NOT_PASSED }
Write-Host "[$scriptName]   LOCAL_WORK_DIR          : $LOCAL_WORK_DIR"

$REMOTE_WORK_DIR = $args[6]
if (-not($REMOTE_WORK_DIR)) {exitWithCode REMOTE_NOT_PASSED }
Write-Host "[$scriptName]   REMOTE_WORK_DIR         : $REMOTE_WORK_DIR"

$ACTION = $args[7]
Write-Host "[$scriptName]   ACTION                  : $ACTION"

$prepackageTasks = "$SOLUTIONROOT\package.tsk"
Write-Host �NoNewLine "[$scriptName]   Prepackage Tasks        : " 
if (Test-Path "$prepackageTasks") {
	Write-Host "found ($prepackageTasks)"
} else {
	Write-Host "none ($prepackageTasks)"
}

$postpackageTasks = "$SOLUTIONROOT\wrap.tsk"
Write-Host �NoNewLine "[$scriptName]   Postpackage Tasks       : " 
if (Test-Path "$postpackageTasks") {
	Write-Host "found ($postpackageTasks)"
} else {
	Write-Host "none ($postpackageTasks)"
}

# Test for optional properties
$remotePropertiesDir = "$SOLUTIONROOT\propertiesForRemoteTasks"
Write-Host �NoNewLine "[$scriptName]   Remote Target Directory : " 

if ( Test-Path $remotePropertiesDir ) {
	Write-Host "found ($remotePropertiesDir)"
} else {
	Write-Host "none ($remotePropertiesDir)"
}

# Runtime information, build process can have large logging, so this is repeated
Write-Host "[$scriptName]   pwd                     : $(pwd)"
Write-Host "[$scriptName]   hostname                : $(hostname)" 
Write-Host "[$scriptName]   whoami                  : $(whoami)" 

$propertiesFile = "$AUTOMATIONROOT\CDAF.windows"
$propName = "productVersion"
try {
	$cdafVersion=$(& .\$AUTOMATIONROOT\remote\getProperty.ps1 $propertiesFile $propName)
	if(!$?){ taskWarning }
} catch { exitWithCode "PACK_GET_CDAF_VERSION" }
Write-Host "[$scriptName]   CDAF Version            : $cdafVersion"

# Cannot brute force clear the workspace as the Visual Studio solution file is here
write-host
write-host "[$scriptName]   --- Start Package Process ---" -ForegroundColor Green
Write-Host
itemRemove .\*.txt
itemRemove .\*.zip
itemRemove .\*.nupkg
itemRemove $LOCAL_WORK_DIR
itemRemove $REMOTE_WORK_DIR
itemRemove artifacts

if ( $ACTION -eq "clean" ) {

	Write-Host
	write-host "[$scriptName] Clean only." -ForegroundColor Blue

} else {

	# Process solution properties if defined
	if (Test-Path "$SOLUTIONROOT\CDAF.solution") {
		write-host 
		write-host "[$scriptName] Load solution properties from $SOLUTIONROOT\CDAF.solution"
		& .\$AUTOMATIONROOT\remote\Transform.ps1 "$SOLUTIONROOT\CDAF.solution" | ForEach-Object { invoke-expression $_ }
	}

	# Process optional pre-packaging tasks (Task driver support added in release 0.7.2)
    if (Test-Path "$prepackageTasks") {
		Write-Host
		Write-Host "[$scriptName] Process Pre-Package Tasks ..."
		Write-Host
		& .\$AUTOMATIONROOT\remote\execute.ps1 $SOLUTION $BUILDNUMBER "package" "$prepackageTasks" $ACTION
		if(!$?){ exitWithCode "..\$AUTOMATIONROOT\remote\execute.ps1 $SOLUTION $BUILDNUMBER `"package`" `"$prepackageTasks`" $ACTION" }
	}

	# Load Manifest, these properties are used by remote deployment
	Add-Content manifest.txt "# Manifest for revision $REVISION"
	Add-Content manifest.txt "SOLUTION=$SOLUTION"
	Add-Content manifest.txt "BUILDNUMBER=$BUILDNUMBER"
	# CDM-115 Add solution properties to manifest if it exists
	if ((Test-Path "$SOLUTIONROOT\CDAF.solution") -and ($item -ne $LOCAL_WORK_DIR) -and ($item -ne $REMOTE_WORK_DIR)) {
		Get-Content $SOLUTIONROOT\CDAF.solution | Add-Content manifest.txt
	}
	Write-Host
	Write-Host "Created manifest.txt file ..."
	Write-Host
	Get-Content manifest.txt
	Write-Host
	write-host "[$scriptName] Always create local working artefacts, even if all tasks are remote" -ForegroundColor Blue
	try {
		& .\$AUTOMATIONROOT\buildandpackage\packageLocal.ps1 $SOLUTION $BUILDNUMBER $REVISION $LOCAL_WORK_DIR $SOLUTIONROOT $AUTOMATIONROOT
		if(!$?){ taskWarning }
	} catch { exitWithCode("packageLocal.ps1") }

	if (( Test-Path "$remotePropertiesDir" -pathtype container) -or ( Test-Path "$SOLUTIONROOT\storeForRemote" -pathtype leaf)) {

		try {
			& .\$AUTOMATIONROOT\buildandpackage\packageRemote.ps1 $SOLUTION $BUILDNUMBER $REVISION $LOCAL_WORK_DIR $REMOTE_WORK_DIR $SOLUTIONROOT $AUTOMATIONROOT
			if(!$?){ taskWarning }
		} catch { exitWithCode("packageRemote.ps1") }

	} else {
		write-host "[$scriptName] Remote Properties directory ($remotePropertiesDir) or storeForRemote file do not exist, no action performed for remote task packaging" -ForegroundColor Yellow
	}

	# Process optional post-packaging tasks (wrap.tsk added in release 0.8.2)
    if (Test-Path "$postpackageTasks") {
		Write-Host
		Write-Host "[$scriptName] Process Post-Package Tasks ..."
		Write-Host
		& .\$AUTOMATIONROOT\remote\execute.ps1 $SOLUTION $BUILDNUMBER "package" "$postpackageTasks" $ACTION
		if(!$?){ exitWithCode "..\$AUTOMATIONROOT\remote\execute.ps1 $SOLUTION $BUILDNUMBER `"package`" `"$postpackageTasks`" $ACTION" }
	}

}
write-host
write-host "[$scriptName]   --- Package Complete ---" -ForegroundColor Green
