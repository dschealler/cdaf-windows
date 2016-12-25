function executeExpression ($expression) {
	$error.clear()
	Write-Host "[$scriptName] $expression"
	try {
		Invoke-Expression $expression
	    if(!$?) { Write-Host "[$scriptName] `$? = $?"; exit 1 }
	} catch { echo $_.Exception|format-list -force; exit 2 }
    if ( $error[0] ) { Write-Host "[$scriptName] `$error[0] = $error"; exit 3 }
}

$scriptName = 'IISAddApp.ps1'
Write-Host
Write-Host "[$scriptName] ---------- start ----------"
$app = $args[0]
if ($app) {
    Write-Host "[$scriptName] app          : $app"
} else {
    Write-Host "[$scriptName] app no supplied"
    exit 100
}

$physicalPath = $args[1]
if ($physicalPath) {
    Write-Host "[$scriptName] physicalPath : $physicalPath"
} else {
	$physicalPath = 'c:\inetpub\' + $app
    Write-Host "[$scriptName] physicalPath : $physicalPath (default)"
}

$site = $args[2]
if ($site) {
    Write-Host "[$scriptName] site         : $site"
} else {
	$site = 'Default Web Site'
    Write-Host "[$scriptName] site         : $site (default)"
}

$appPool = $args[3]
if ($appPool) {
    Write-Host "[$scriptName] appPool      : $appPool"
} else {
    Write-Host "[$scriptName] appPool      : (not supplied)"
}

$clrVersion = $args[4]
if ($clrVersion) {
    Write-Host "[$scriptName] clrVersion   : $clrVersion"
} else {
    Write-Host "[$scriptName] clrVersion   : (not supplied)"
}
Write-Host

if (Test-Path "$physicalPath") {
    Write-Host "[$scriptName] Physical path $physicalPath exists, no action required."
} else {
	executeExpression "New-Item -ItemType Directory -Force -Path `'$physicalPath`'"
}

executeExpression 'import-module WebAdministration'

if ($appPool) {
	if (Test-Path "IIS:\AppPools\$appPool") {
	    Write-Host "[$scriptName] Application Pool $appPool exists"
	} else {
		executeExpression "New-Item `'IIS:\AppPools\$appPool`'"
	}
}

if ($clrVersion) {
	if ($clrVersion -like "NoManagedCode") {
		executeExpression "Set-ItemProperty `'IIS:\AppPools\$appPool`' managedRuntimeVersion `'`' "
	} else {
		executeExpression "Set-ItemProperty `'IIS:\AppPools\$appPool`' managedRuntimeVersion `'$clrVersion`'"
	}
}

if (Test-Path "IIS:\Sites\$site\$app") {
    Write-Host "[$scriptName] Site IIS:\Sites\$site\$app exists"
} else {
	executeExpression "New-Item `'IIS:\Sites\$site\$app`' -PhysicalPath `'$physicalPath`' -Type Application"
}

if ($appPool) {
	executeExpression "Set-ItemProperty `'IIS:\Sites\$site\$app`' -name applicationPool -value `'$appPool`'"
}
Write-Host
Write-Host "[$scriptName] List application pool version"
Write-Host
foreach ($pool in Get-Item "IIS:\AppPools\*") {
	$poolName = $($pool).name
	Write-Host "  $poolName : $((Get-ItemProperty IIS:\AppPools\$poolName managedRuntimeVersion).value)"
}
	
Write-Host
Write-Host "[$scriptName] List Sites"
Write-Host
executeExpression "Get-Item `'IIS:\Sites\*`'"
	
Write-Host
Write-Host "[$scriptName] ---------- stop ----------"
