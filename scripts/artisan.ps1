param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArtisanArguments = @('serve')
)
$ErrorActionPreference = 'Stop'
$backendPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'backend'
$phpCommand = Get-Command php -ErrorAction SilentlyContinue
$phpPath = if ($phpCommand) { $phpCommand.Source } else { 'C:\xampp\php\php.exe' }
if (-not (Test-Path -LiteralPath $phpPath)) {
    throw 'PHP was not found. Add PHP to PATH or install it at C:\xampp\php.'
}
$env:Path = (Split-Path -Parent $phpPath) + ';' + $env:Path
Push-Location -LiteralPath $backendPath
try {
    & $phpPath artisan @ArtisanArguments
    $commandExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $commandExitCode
