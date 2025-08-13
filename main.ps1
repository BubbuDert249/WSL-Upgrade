Add-Type -AssemblyName System.Windows.Forms

# Check if running as admin
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $null = [System.Windows.Forms.MessageBox]::Show("The WSL Upgrade needs to be run as Administrator.","WSL Upgrade","OK","Warning")
    Exit
}

# Check WSL version installed
$wslVersion = wsl --version 2>$null
if (-not $wslVersion) {
    $null = [System.Windows.Forms.MessageBox]::Show("WSL is not installed. Please install WSL first.","Error","OK","Error")
    Exit
}

# Get all distros and their WSL versions
$distros = wsl --list --verbose | Select-Object -Skip 1 | ForEach-Object {
    if ($_ -match "(\S+)\s+Running|Stopped\s+(\d)") {
        $name = $matches[1]
        $version = [int]$matches[2]
        [PSCustomObject]@{Name=$name; Version=$version}
    }
} | Where-Object { $_ }

# Filter distros that are still WSL 1
$needsUpgrade = $distros | Where-Object { $_.Version -eq 1 }

if ($needsUpgrade.Count -eq 0) {
    $null = [System.Windows.Forms.MessageBox]::Show("The WSL version is already 2.","WSL Upgrade","OK","Information")
    Exit
}

# Ensure WSL 2 optional features are installed (if not already)
wsl --set-default-version 2 2>$null

# Upgrade distros with single progress bar
$total = $needsUpgrade.Count
$count = 0

foreach ($distro in $needsUpgrade) {
    Write-Host "Upgrading $($distro.Name) to WSL 2..."
    wsl --set-version $distro.Name 2
    $count++
    Write-Progress -Activity "Upgrading WSL 1 distros to WSL 2" `
                   -Status "$count of $total distros upgraded" `
                   -PercentComplete (($count / $total) * 100)
}

Write-Progress -Activity "Upgrade Complete" -Completed
$null = [System.Windows.Forms.MessageBox]::Show("WSL 1 upgraded to WSL 2","Upgrade Complete","OK","Information")
