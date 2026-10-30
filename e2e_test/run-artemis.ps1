param(
  [int]$RunsPerTest = 3,
  [string]$OutputDirectory = '.\evidence\artemis'
)

$ErrorActionPreference = 'Stop'
if ($RunsPerTest -lt 3) { throw 'Lab 3 requires at least three Flash runs per test.' }
if (-not $env:ARTEMIS_BASE_URL) { throw 'Set ARTEMIS_BASE_URL to the running ARTEMIS host.' }
if (-not $env:ARTEMIS_DEVICE_SERIAL) { throw 'Set ARTEMIS_DEVICE_SERIAL to the connected test device.' }

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$manifest = [System.Collections.Generic.List[object]]::new()

Push-Location $repoRoot
try {
  for ($run = 1; $run -le $RunsPerTest; $run++) {
    $testName = "flash-suite-run-$run"
    $logPath = Join-Path $resolvedOutput "$testName.log"
    $junitPath = Join-Path $resolvedOutput "$testName.junit.xml"
    Write-Host "Running all independent Flash tests, pass $run/$RunsPerTest"
    & uv run --project .\e2e_test pytest -c .\e2e_test\pyproject.toml .\e2e_test `
      -m 'not exploratory and not manual_setup' -q -s `
      --junitxml $junitPath 2>&1 | Tee-Object -FilePath $logPath
    $exitCode = $LASTEXITCODE
    $manifest.Add([pscustomobject]@{
        suiteRun = $run
        profile = 'flash'
        deviceSerial = $env:ARTEMIS_DEVICE_SERIAL
        exitCode = $exitCode
        log = $logPath
        junit = $junitPath
        recordedAtLocal = (Get-Date).ToString('o')
      })
  }

  $manifestPath = Join-Path $resolvedOutput 'run-manifest.json'
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
  if (@($manifest | Where-Object exitCode -ne 0).Count -gt 0) {
    throw "One or more suite runs failed. Inspect logs and raw traces in $resolvedOutput"
  }
  Write-Host "Saved run manifest: $manifestPath"
  Write-Host 'This suite excludes the three manual FCM cases. Run those separately three times, sending a fresh Firebase Console test message before each run.'
  Write-Host 'Check each JUnit result against its ARTEMIS trace and verify the reported JSON values before claiming a pass.'
}
finally {
  Pop-Location
}
