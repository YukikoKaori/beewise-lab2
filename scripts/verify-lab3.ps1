param(
  [string]$Flutter = 'flutter',
  [string]$CacheRoot = 'D:\CodexTemp\beewise-lab3-cache',
  [switch]$Rules,
  [switch]$Android
)
$ErrorActionPreference = 'Stop'
$env:PUB_CACHE = Join-Path $CacheRoot 'pub'
$env:GRADLE_USER_HOME = Join-Path $CacheRoot 'gradle'
$env:npm_config_cache = Join-Path $CacheRoot 'npm'
$env:FIREBASE_EMULATORS_PATH = Join-Path $CacheRoot 'firebase-emulators'
New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null
$env:TEMP = $CacheRoot
$env:TMP = $CacheRoot
function Run-Checked([string]$Executable, [string[]]$Arguments) {
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Executable $Arguments exited $LASTEXITCODE" }
}
Run-Checked $Flutter @('--version')
Run-Checked $Flutter @('pub', 'get', '--enforce-lockfile')
$dart = if (Test-Path -LiteralPath $Flutter) { Join-Path (Split-Path $Flutter) 'dart.bat' } else { 'dart' }
Run-Checked $dart @('format', '--output=none', '--set-exit-if-changed', '.')
Run-Checked $Flutter @('analyze')
Run-Checked $Flutter @('test', '--reporter', 'expanded')
Run-Checked 'python' @('scripts/check_e2e_harness.py')
if ($Rules) {
  Run-Checked 'npm.cmd' @('ci', '--prefix', 'firebase', '--ignore-scripts')
  Run-Checked 'npm.cmd' @('--prefix', 'firebase', 'test')
}
if ($Android) { Run-Checked $Flutter @('build', 'apk', '--debug') }
