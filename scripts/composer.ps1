param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposerArguments = @('install')
)
$ErrorActionPreference = 'Stop'
$backendPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'backend'
$phpCommand = Get-Command php -ErrorAction SilentlyContinue
$phpPath = if ($phpCommand) { $phpCommand.Source } else { 'C:\xampp\php\php.exe' }
$composerPhar = 'C:\ProgramData\ComposerSetup\bin\composer.phar'
if (-not (Test-Path -LiteralPath $phpPath)) { throw 'PHP was not found.' }
$env:Path = (Split-Path -Parent $phpPath) + ';' + $env:Path
Push-Location -LiteralPath $backendPath
try {
    if (Test-Path -LiteralPath $composerPhar) {
        $zipLoaded = (& $phpPath -m) -contains 'zip'
        if ($zipLoaded) {
            & $phpPath $composerPhar @ComposerArguments
        } else {
            & $phpPath -d extension=zip $composerPhar @ComposerArguments
        }
    } else {
        $composerCommand = Get-Command composer -ErrorAction Stop
        & $composerCommand.Source @ComposerArguments
    }
    $commandExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $commandExitCode
