# Common expression logging and error handling function, copied, not referenced to ensure atomic process
function executeExpression ($expression) {
	$error.clear()
	Write-Host "[$scriptName] $expression"
	try {
		Invoke-Expression $expression
	    if(!$?) { Write-Host "[$scriptName] `$? = $?"; exit 1 }
	} catch { echo $_.Exception|format-list -force; exit 2 }
    if ( $error[0] ) { Write-Host "[$scriptName] `$error[0] = $error"; exit 3 }
}

$scriptName = 'setenv.ps1'
Write-Host
Write-Host "[$scriptName] ---------- start ----------"
$variable = $args[0]
$value    = $args[1]
$target   = $args[2]

# vagrant file share is dependant on provider, for VirtualBox, pass as C:\.provision
if ($variable) {
    Write-Host "[$scriptName] variable : $variable"
} else {
	$mediaDir = '/.provision'
    Write-Host "[$scriptName] mediaDir : $mediaDir (default)"
}

if ($value) {
    Write-Host "[$scriptName] value    : $value"
} else {
    Write-Host "[$scriptName] value required, exiting!"
    exit 101
}

if ($target) {
    Write-Host "[$scriptName] target   : $target"
} else {
	$target = 'user'
    Write-Host "[$scriptName] target   : $target (default, choices user or machine)"
}

Write-Host
executeExpression "[Environment]::SetEnvironmentVariable(`'$variable`', `'$value`', `'$target`')"

Write-Host
Write-Host "[$scriptName] ---------- stop -----------"
Write-Host