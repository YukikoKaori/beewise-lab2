param([string]$Bundle = 'D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/firestore-auth-bootstrap-20261031')
# Local demo-project emulators only. No shared deployment is implemented here.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot
$toolRoot = 'D:/CodexTemp/beewise-lab3-tools'
$manifest = Get-Content -LiteralPath "$Bundle/manifest.json" -Raw | ConvertFrom-Json
foreach ($entry in $manifest.fileSha256.PSObject.Properties) {
  $hasher = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.IO.File]::ReadAllBytes((Join-Path $Bundle $entry.Name))
  try { $actualHash = ([BitConverter]::ToString($hasher.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
  finally { $hasher.Dispose() }
  if ($actualHash -ne $entry.Value) {
    throw "Frozen bundle changed: $($entry.Name)"
  }
}
$env:JAVA_HOME = "$toolRoot/jdk/jdk-21.0.13+9"
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
$env:TEMP = $toolRoot
$env:TMP = $toolRoot
$env:FIREBASE_EMULATORS_PATH = "$toolRoot/emulator-cache"
$env:NODE_PATH = "$repoRoot/firebase/node_modules"
$out = "$repoRoot/evidence/cloud/checks/auth-frozen-bundle"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$started = [DateTime]::UtcNow.ToString('o')
Set-Location -LiteralPath $Bundle
$ErrorActionPreference = 'Continue'
& node "$repoRoot/firebase/node_modules/firebase-tools/lib/bin/firebase.js" emulators:exec --config "$Bundle/firebase.validation.json" --project demo-beewise --only firestore,storage 'node --test rules.test.cjs' 2>&1 | Tee-Object "$out/rules-test.log"
$nativeExit = $LASTEXITCODE
@{startedAtUtc=$started; completedAtUtc=[DateTime]::UtcNow.ToString('o'); sourceSha=$manifest.sourceSha; projectId='demo-beewise'; bundleDirectory=$Bundle; fileSha256=$manifest.fileSha256; nativeExitCode=$nativeExit; sharedDeploymentPerformed=$false} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 "$out/rules-test.json"
exit $nativeExit
