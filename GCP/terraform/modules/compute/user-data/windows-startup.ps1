# Windows Startup Script for GCP
# This script configures Windows instances for remote management

param(
    [string]$AdminUsername = "brine",
    [string]$AdminPassword = "Bravedemo123."
)

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Function to log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath "C:\startup-log.txt" -Append -Encoding UTF8
    Write-Output $Message
}

Write-Log "Starting Windows configuration script"

try {
    # Enable RDP
    Write-Log "Enabling Remote Desktop"
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

    # Create admin user
    Write-Log "Creating admin user: $AdminUsername"
    $securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    
    if (-not (Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $AdminUsername -Password $securePassword -FullName "$AdminUsername User" -PasswordNeverExpires -ErrorAction Stop
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername -ErrorAction Stop
        Write-Log "Admin user created successfully"
    } else {
        Set-LocalUser -Name $AdminUsername -Password $securePassword
        Write-Log "Admin user already exists, password updated"
    }

    # Configure WinRM for Ansible
    Write-Log "Configuring WinRM for remote management"
    
    # Enable PowerShell Remoting
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    
    # Configure WinRM service
    winrm quickconfig -quiet -transport:http
    
    # Set WinRM configuration
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
    Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 512
    Set-Item -Path WSMan:\localhost\MaxTimeoutms -Value 1800000
    
    # Remove existing HTTP listener and create new one
    Remove-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address="*";Transport="HTTP"} -ErrorAction SilentlyContinue
    New-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address="*";Transport="HTTP"} -ValueSet @{Port="5985"}
    
    # Configure HTTPS listener (optional, more secure)
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    New-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address="*";Transport="HTTPS"} -ValueSet @{Hostname=$env:COMPUTERNAME;CertificateThumbprint=$cert.Thumbprint;Port="5986"}
    
    # Configure Windows Firewall
    Write-Log "Configuring Windows Firewall rules"
    
    # WinRM HTTP
    New-NetFirewallRule -DisplayName "WinRM-HTTP-In" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    
    # WinRM HTTPS
    New-NetFirewallRule -DisplayName "WinRM-HTTPS-In" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    
    # Enable file and printer sharing (for management)
    Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"
    
    # Restart WinRM service
    Write-Log "Restarting WinRM service"
    Restart-Service WinRM -Force
    
    # Set WinRM to start automatically
    Set-Service WinRM -StartupType Automatic
    
    # Additional security configurations
    Write-Log "Applying security configurations"
    
    # Disable Windows Defender real-time monitoring (optional, for testing)
    # Set-MpPreference -DisableRealtimeMonitoring $true
    
    # Enable Windows Update
    Set-Service wuauserv -StartupType Automatic
    Start-Service wuauserv
    
    # Set time zone (adjust as needed)
    Set-TimeZone -Name "Eastern Standard Time"
    
    # Install useful PowerShell modules
    Write-Log "Installing PowerShell modules"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber
    
    Write-Log "Windows configuration completed successfully"
    
} catch {
    Write-Log "ERROR: $_"
    Write-Log $_.Exception.StackTrace
}

# Restart Terminal Services to ensure RDP is working
Write-Log "Restarting Terminal Services"
Restart-Service TermService -Force

# Create a marker file to indicate script completion
"Configuration completed at $(Get-Date)" | Out-File -FilePath "C:\startup-complete.txt"

Write-Log "Script execution finished"