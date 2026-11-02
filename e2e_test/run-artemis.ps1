param(
  [int]$RunsPerTest = 3,
  [string]$OutputDirectory = '.\evidence\artemis'
)

$ErrorActionPreference = 'Stop'
if ($RunsPerTest -lt 3) { throw 'Lab 3 requires at least three Flash runs per test.' }
$CaseIds = @($env:ARTEMIS_CASE_IDS -split '[,|]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($CaseIds.Count -eq 0) {
  throw 'ARTEMIS_CASE_IDS must explicitly select one or more approved non-business-mutation cases; refusing to run the full suite by default.'
}
$allowedCaseIds = @('TC-01', 'TC-02', 'TC-03', 'TC-04', 'TC-05', 'TC-06', 'TC-07', 'TC-08', 'TC-09', 'TC-12', 'TC-13', 'TC-16', 'TC-17', 'TC-27')
foreach ($caseId in $CaseIds) {
  if ($caseId -notin $allowedCaseIds) {
    throw "Case '$caseId' is outside the non-business-mutation subset. Use a dedicated staging project and review its side effects before running other cases."
  }
}
if ($CaseIds.Count -gt 0 -and @($CaseIds | Select-Object -Unique).Count -ne $CaseIds.Count) {
  throw 'CaseIds must not contain duplicates.'
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
  [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
  [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
}
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$manifest = [System.Collections.Generic.List[object]]::new()
$manifestPath = Join-Path $resolvedOutput 'run-manifest.json'
if (Test-Path -LiteralPath $manifestPath) { throw 'Use a fresh output directory; preserve previous evidence.' }
$missing = [System.Collections.Generic.List[string]]::new()
$shaOutput = @(& git -C $repoRoot rev-parse HEAD 2>$null)
$gitExitCode = $LASTEXITCODE
$sourceSha = if ($gitExitCode -eq 0 -and $shaOutput.Count -gt 0) { $shaOutput[0] } else { 'UNAVAILABLE' }
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { $missing.Add('uv') }
if (-not $env:ARTEMIS_BASE_URL) { $missing.Add('ARTEMIS_BASE_URL') }
if (-not $env:ARTEMIS_DEVICE_SERIAL) { $missing.Add('ARTEMIS_DEVICE_SERIAL') }
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbCommand) {
  $missing.Add('adb executable')
} else {
  $adbOutput = @()
  $adbExitCode = 1
  try {
    $adbOutput = @(& $adbCommand.Source devices 2>$null)
    $adbExitCode = $LASTEXITCODE
  } catch { $adbOutput = @(); $adbExitCode = 1 }
  if ($adbExitCode -ne 0) {
    $missing.Add('working ADB daemon')
  } elseif ($env:ARTEMIS_DEVICE_SERIAL) {
    $connected = $adbOutput | Select-String -Pattern ('^' + [regex]::Escape($env:ARTEMIS_DEVICE_SERIAL) + '\s+device$')
    if (-not $connected) { $missing.Add('online authorized ARTEMIS_DEVICE_SERIAL') }
  } else {
    $onlineDevices = @($adbOutput | Select-String -Pattern '^\S+\s+device$')
    if ($onlineDevices.Count -eq 0) { $missing.Add('online authorized Android device') }
  }
}
if ($missing.Count -gt 0) {
  [pscustomobject]@{ status = 'BLOCKED'; sourceSha = $sourceSha; missing = @($missing); recordedAtUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
  Write-Host "ARTEMIS preflight blocked: $($missing -join ', ')"
  exit 2
}
$exitCode = 0

Push-Location $repoRoot
try {
  for ($run = 1; $run -le $RunsPerTest; $run++) {
    $testName = "flash-suite-run-$run"
    $logPath = Join-Path $resolvedOutput "$testName.log"
    $junitPath = Join-Path $resolvedOutput "$testName.junit.xml"
    $selectedCases = @($CaseIds)
    Write-Host "Running Flash tests [$($selectedCases -join ', ')], pass $run/$RunsPerTest"
    $ErrorActionPreference = 'Continue'
    $pytestArgs = @(
      'run', '--project', '.\e2e_test', 'pytest',
      '-c', '.\e2e_test\pyproject.toml', '.\e2e_test',
      '-m', 'not exploratory and not manual_setup', '-q', '-s',
      '--junitxml', $junitPath
    )
    $filter = ($CaseIds | ForEach-Object { "test_tc$($_.Substring(3))_" }) -join ' or '
    $pytestArgs += @('-k', $filter)
    & uv @pytestArgs 2>&1 | Tee-Object -FilePath $logPath
    $runExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($runExitCode -ne 0 -and $exitCode -eq 0) { $exitCode = $runExitCode }
    $runStatus = if ($runExitCode -eq 0) { 'PENDING_VERIFICATION' } else { 'FAIL' }
    if ($runExitCode -ne 0 -and (Get-Content -LiteralPath $logPath -Raw) -match 'provider quota/rate-limit error') {
      $runStatus = 'BLOCKED_QUOTA'
    }
    $hashStream = [System.IO.File]::OpenRead($logPath)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { $logSha256 = [BitConverter]::ToString($hasher.ComputeHash($hashStream)).Replace('-', '') }
    finally { $hashStream.Dispose(); $hasher.Dispose() }
    $manifest.Add([pscustomobject]@{
        suiteRun = $run
        profile = 'flash'
        selectedCases = @($selectedCases)
        deviceSerial = $env:ARTEMIS_DEVICE_SERIAL
        exitCode = $runExitCode
        status = $runStatus
        sourceSha = $sourceSha
        logSha256 = $logSha256
        log = $logPath
        junit = $junitPath
        recordedAtUtc = [DateTime]::UtcNow.ToString('o')
      })
    ConvertTo-Json -InputObject $manifest.ToArray() -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    if ($runStatus -eq 'BLOCKED_QUOTA') {
      Write-Host 'Stopping batch: ARTEMIS provider quota/rate limit detected; later suite runs were not submitted.'
      break
    }
  }

  $manifestPath = Join-Path $resolvedOutput 'run-manifest.json'
  ConvertTo-Json -InputObject $manifest.ToArray() -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
  Write-Host "Saved run manifest: $manifestPath"
  Write-Host 'Excludes TC-10/14/15 (fresh manual FCM) and TC-26 (operator-entered test credentials). Run each separately three times.'
  Write-Host 'Check each JUnit result against its ARTEMIS trace and verify the reported JSON values before claiming a pass.'
}
catch {
  if ($exitCode -eq 0) { $exitCode = 1 }
  $manifest.Add([pscustomobject]@{ status = 'FAIL'; sourceSha = $sourceSha; reason = $_.Exception.Message; exitCode = $exitCode })
  ConvertTo-Json -InputObject $manifest.ToArray() -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
}
finally {
  Pop-Location
}
exit $exitCode
