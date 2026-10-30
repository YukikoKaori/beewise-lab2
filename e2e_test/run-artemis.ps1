param(
  [int]$RunsPerTest = 3,
  [string]$OutputDirectory = '.\evidence\artemis'
)

$ErrorActionPreference = 'Stop'
if ($RunsPerTest -lt 3) { throw 'Lab 3 requires at least three Flash runs per test.' }

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$manifest = [System.Collections.Generic.List[object]]::new()
$manifestPath = Join-Path $resolvedOutput 'run-manifest.json'
if (Test-Path -LiteralPath $manifestPath) { throw 'Use a fresh output directory; preserve previous evidence.' }
$sourceSha = & git -C $repoRoot rev-parse HEAD
if (-not $env:ARTEMIS_BASE_URL -or -not $env:ARTEMIS_DEVICE_SERIAL -or -not (Get-Command uv -ErrorAction SilentlyContinue)) {
  [pscustomobject]@{ status = 'BLOCKED'; sourceSha = $sourceSha; reason = 'Need uv, ARTEMIS host and online Android device'; recordedAtUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8
  exit 2
}
$exitCode = 0

Push-Location $repoRoot
try {
  for ($run = 1; $run -le $RunsPerTest; $run++) {
    $testName = "flash-suite-run-$run"
    $logPath = Join-Path $resolvedOutput "$testName.log"
    $junitPath = Join-Path $resolvedOutput "$testName.junit.xml"
    Write-Host "Running all independent Flash tests, pass $run/$RunsPerTest"
    $ErrorActionPreference = 'Continue'
    & uv run --project .\e2e_test pytest -c .\e2e_test\pyproject.toml .\e2e_test `
      -m 'not exploratory and not manual_setup' -q -s `
      --junitxml $junitPath 2>&1 | Tee-Object -FilePath $logPath
    $runExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($runExitCode -ne 0 -and $exitCode -eq 0) { $exitCode = $runExitCode }
    $hashStream = [System.IO.File]::OpenRead($logPath)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { $logSha256 = [BitConverter]::ToString($hasher.ComputeHash($hashStream)).Replace('-', '') }
    finally { $hashStream.Dispose(); $hasher.Dispose() }
    $manifest.Add([pscustomobject]@{
        suiteRun = $run
        profile = 'flash'
        deviceSerial = $env:ARTEMIS_DEVICE_SERIAL
        exitCode = $runExitCode
        status = $(if ($runExitCode -eq 0) { 'PENDING_VERIFICATION' } else { 'FAIL' })
        sourceSha = $sourceSha
        logSha256 = $logSha256
        log = $logPath
        junit = $junitPath
        recordedAtUtc = [DateTime]::UtcNow.ToString('o')
      })
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
  }

  $manifestPath = Join-Path $resolvedOutput 'run-manifest.json'
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
  Write-Host "Saved run manifest: $manifestPath"
  Write-Host 'Excludes TC-10/14/15 (fresh manual FCM) and TC-26 (operator-entered test credentials). Run each separately three times.'
  Write-Host 'Check each JUnit result against its ARTEMIS trace and verify the reported JSON values before claiming a pass.'
}
catch {
  if ($exitCode -eq 0) { $exitCode = 1 }
  $manifest.Add([pscustomobject]@{ status = 'FAIL'; sourceSha = $sourceSha; reason = $_.Exception.Message; exitCode = $exitCode })
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
}
finally {
  Pop-Location
}
exit $exitCode
