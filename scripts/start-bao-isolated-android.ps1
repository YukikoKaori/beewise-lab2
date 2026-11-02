param([string]$Sdk = 'D:\Android\SDK', [int]$Port = 5558, [switch]$Visible)
# Creates/reuses only this workstream's separate AVD; never wipes or copies user data.
$ErrorActionPreference = 'Stop'
$avdRoot = 'D:\CodexTemp\beewise-lab3-tools\bao-isolated-avd'
$name = 'BeeWise_Bao_PR3_API37'
$content = Join-Path $avdRoot "$name.avd"
$image = Join-Path $Sdk 'system-images\android-37.0\google_apis_playstore\x86_64'
if (!(Test-Path -LiteralPath "$image\system.img")) { throw 'Existing API37 system image required.' }
New-Item -ItemType Directory -Force -Path $content | Out-Null
if (!(Test-Path -LiteralPath "$content\config.ini")) {
  @"
AvdId=$name
avd.ini.displayname=BeeWise Bao PR3 isolated
avd.ini.encoding=UTF-8
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=2
hw.ramSize=4096
hw.gpu.enabled=yes
hw.gpu.mode=software
hw.lcd.width=720
hw.lcd.height=1600
hw.lcd.density=320
hw.keyboard=yes
hw.mainKeys=no
disk.dataPartition.size=6G
image.sysdir.1=$image\
tag.id=google_apis_playstore
tag.display=Google Play
PlayStore.enabled=true
target=android-37
skin.dynamic=yes
skin.name=720x1600
vm.heapSize=256
fastboot.forceColdBoot=yes
"@ | Set-Content -LiteralPath "$content\config.ini" -Encoding ASCII
  "avd.ini.encoding=UTF-8`npath=$content`ntarget=android-37`n" | Set-Content -LiteralPath "$avdRoot\$name.ini" -Encoding ASCII
}
$env:ANDROID_AVD_HOME = $avdRoot
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:TEMP = 'D:\CodexTemp\beewise-lab3-tools'
$env:TMP = $env:TEMP
$arguments = @('-avd', $name, '-port', "$Port", '-no-snapshot', '-no-boot-anim', '-memory', '4096', '-gpu', 'software', '-cores', '2', '-no-audio', '-show-kernel')
$windowStyle = 'Hidden'
if ($Visible) { $windowStyle = 'Normal' } else { $arguments += '-no-window' }
# Visible mode is only for the user's interactive test login; no credentials scripted.
$process = Start-Process -FilePath "$Sdk\emulator\emulator.exe" -ArgumentList $arguments -WindowStyle $windowStyle -PassThru -RedirectStandardOutput "$avdRoot\stdout.log" -RedirectStandardError "$avdRoot\stderr.log"
@{createdAtUtc=[DateTime]::UtcNow.ToString('o'); name=$name; directory=$content; port=$Port; processId=$process.Id; arguments=$arguments; noWipe=$true} | ConvertTo-Json | Set-Content -LiteralPath "$avdRoot\launch.json" -Encoding UTF8
Write-Output "Started isolated $name on emulator-$Port (PID $($process.Id)); original emulator untouched."
