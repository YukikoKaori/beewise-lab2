param(
  [ValidateSet('pub','format','focused','check','rules','build','toolchain')]
  [string]$Action = 'check',
  [string]$ToolRoot = 'D:\CodexTemp\beewise-lab3-tools',
  [string]$BuildDirectory = '',
  [string]$RunName = 'final'
)
$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path $PSScriptRoot
$logRoot = Join-Path $repoRoot "evidence/cloud/checks/$RunName"
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$flutter = Join-Path $ToolRoot 'flutter/bin/flutter.bat'
$dart = Join-Path $ToolRoot 'flutter/bin/dart.bat'
$env:PUB_CACHE = Join-Path $ToolRoot 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $ToolRoot 'gradle-cache-d-build'
$env:npm_config_cache = Join-Path $ToolRoot 'npm-cache'
$env:FIREBASE_EMULATORS_PATH = Join-Path $ToolRoot 'emulator-cache'
$env:JAVA_HOME = Join-Path $ToolRoot 'jdk/jdk-21.0.13+9'
$env:ANDROID_HOME = 'D:\Android\SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:TEMP = $ToolRoot
$env:TMP = $ToolRoot
$env:PATH = "$(Split-Path $flutter);$env:JAVA_HOME/bin;$env:ANDROID_HOME/platform-tools;$env:PATH"
foreach ($required in @($flutter, $dart, "$env:JAVA_HOME/bin/java.exe", "$env:ANDROID_HOME/platform-tools/adb.exe")) {
  if (!(Test-Path -LiteralPath $required)) { throw "Missing verified tool: $required" }
}
function Run-Checked([string]$Name, [string]$Executable, [string[]]$Arguments) {
  $started = [DateTime]::UtcNow.ToString('o')
  & $Executable @Arguments 2>&1 | Tee-Object (Join-Path $logRoot "$Name.log")
  $nativeExit = $LASTEXITCODE
  $result = [ordered]@{
    startedAtUtc=$started; completedAtUtc=[DateTime]::UtcNow.ToString('o')
    sourceSha=(& git rev-parse HEAD); workingDirectory=(Get-Location).Path
    command="$Executable $($Arguments -join ' ')"; nativeExitCode=$nativeExit
  }
  $result | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $logRoot "$Name.json")
  if ($nativeExit -ne 0) { exit $nativeExit }
}
Set-Location $repoRoot
switch ($Action) {
  'pub' { Run-Checked 'pub-get' $flutter @('pub','get') }
  'format' { Run-Checked 'format-write' $dart @('format','lib/services','lib/viewmodels','test/cloud_services_test.dart') }
  'focused' { Run-Checked 'cloud-services-test' $flutter @('test','test/cloud_services_test.dart','--reporter','expanded') }
  'check' {
    Run-Checked 'pub-lock' $flutter @('pub','get','--enforce-lockfile')
    Run-Checked 'format' $dart @('format','--output=none','--set-exit-if-changed','.')
    Run-Checked 'analyze' $flutter @('analyze')
    Run-Checked 'flutter-test' $flutter @('test','--reporter','expanded')
  }
  'rules' { Run-Checked 'rules-test' 'npm.cmd' @('--prefix','firebase','test') }
  'build' {
    if (!$BuildDirectory) { throw 'Pass the verified clean D worktree with -BuildDirectory.' }
    Set-Location -LiteralPath $BuildDirectory
    Run-Checked 'apk-build' $flutter @('build','apk','--debug')
  }
  'toolchain' {
    Run-Checked 'flutter-version' $flutter @('--version')
    Run-Checked 'flutter-doctor' $flutter @('doctor','-v')
    Run-Checked 'flutter-devices' $flutter @('devices')
    Run-Checked 'adb-devices' 'adb.exe' @('devices','-l')
  }
}
exit 0
