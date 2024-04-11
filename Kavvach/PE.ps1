
######################## FUNCTIONS ########################

# Gather KB from all patches installed
function returnHotFixID {
    param(
        [string]$title
    )
    # Match on KB or if patch does not have a KB, return end result
    if (($title | Select-String -AllMatches -Pattern 'KB(\d{4,6})').Matches.Value) {
        return (($title | Select-String -AllMatches -Pattern 'KB(\d{4,6})').Matches.Value)
    }
    elseif (($title | Select-String -NotMatch -Pattern 'KB(\d{4,6})').Matches.Value) {
        return (($title | Select-String -NotMatch -Pattern 'KB(\d{4,6})').Matches.Value)
    }
}
  
Function Start-ACLCheck {
    param(
        $Target, $ServiceName)
    # Gather ACL of object
    if ($null -ne $target) {
        try {
            $ACLObject = Get-Acl $target -ErrorAction SilentlyContinue
        }
        catch { $null }
      
        # If Found, Evaluate Permissions
        if ($ACLObject) { 
            $Identity = @()
            $Identity += "$env:COMPUTERNAME\$env:USERNAME"
            if ($ACLObject.Owner -like $Identity ) { Write-Host "$Identity has ownership of $Target" -ForegroundColor Red }
            whoami.exe /groups /fo csv | ConvertFrom-Csv | Select-Object -ExpandProperty 'group name' | ForEach-Object { $Identity += $_ }
            $IdentityFound = $false
            foreach ($i in $Identity) {
                $permission = $ACLObject.Access | Where-Object { $_.IdentityReference -like $i }
                $UserPermission = ""
                switch -WildCard ($Permission.FileSystemRights) {
                    "FullControl" { $userPermission = "FullControl"; $IdentityFound = $true }
                    "Write*" { $userPermission = "Write"; $IdentityFound = $true }
                    "Modify" { $userPermission = "Modify"; $IdentityFound = $true }
                }
                Switch ($permission.RegistryRights) {
                    "FullControl" { $userPermission = "FullControl"; $IdentityFound = $true }
                }
                if ($UserPermission) {
                    if ($ServiceName) { Write-Host "$ServiceName found with permissions issue:" -ForegroundColor Red }
                    Write-Host -ForegroundColor red  "Identity $($permission.IdentityReference) has '$userPermission' perms for $Target"
                }
            }    
            # Identity Found Check - If False, loop through and stop at root of drive
            if ($IdentityFound -eq $false) {
                if ($Target.Length -gt 3) {
                    $Target = Split-Path $Target
                    Start-ACLCheck $Target -ServiceName $ServiceName
                }
            }
        }
        else {
            # If not found, split path one level and Check again
            $Target = Split-Path $Target
            Start-ACLCheck $Target $ServiceName
        }
    }
}
  
Function UnquotedServicePathCheck {
    Write-Host "Fetching the list of services, this may take a while...";
    $services = Get-WmiObject -Class Win32_Service | Where-Object { $_.PathName -inotmatch "`"" -and $_.PathName -inotmatch ":\\Windows\\" -and ($_.StartMode -eq "Auto" -or $_.StartMode -eq "Manual") -and ($_.State -eq "Running" -or $_.State -eq "Stopped") };
    if ($($services | Measure-Object).Count -lt 1) {
        Write-Host "No unquoted service paths were found";
    }
    else {
        $services | ForEach-Object {
            Write-Host "Unquoted Service Path found!" -ForegroundColor red
            Write-Host Name: $_.Name
            Write-Host PathName: $_.PathName
            Write-Host StartName: $_.StartName 
            Write-Host StartMode: $_.StartMode
            Write-Host Running: $_.State
        } 
    }
}
  
function TimeElapsed { Write-Host "Time Running: $($stopwatch.Elapsed.Minutes):$($stopwatch.Elapsed.Seconds)" }
  
Function Get-ClipBoardText {
    Add-Type -AssemblyName PresentationCore
    $text = [Windows.Clipboard]::GetText()
    if ($text) {
        Write-Host ""
        TimeElapsed
        Write-Host "=========|| ClipBoard text found:"
        Write-Host $text
      
    }
}
  


  
  
######################## SYSTEM INFORMATION ########################
  
Write-Host ""
TimeElapsed
Write-Host "====================================||SYSTEM INFORMATION ||===================================="
"The following information is curated. To get a full list of system information, run the cmdlet get-computerinfo"
  
#System Info from get-computer info
systeminfo.exe
  
  
#Hotfixes installed sorted by date
Write-Host ""
TimeElapsed
Write-Host "=========|| WINDOWS HOTFIXES"
Write-Host "=| Check if windows is vulnerable -ForegroundColor Yellow
Write-Host "Possible exploits" -ForegroundColor Yellow
$Hotfix = Get-HotFix | Sort-Object -Descending -Property InstalledOn -ErrorAction SilentlyContinue | Select-Object HotfixID, Description, InstalledBy, InstalledOn
$Hotfix | Format-Table -AutoSize
  
  
#Show all unique updates installed
Write-Host ""
TimeElapsed
Write-Host "=========|| ALL UPDATES INSTALLED"
  
  
# 0, and 5 are not used for history
  
$session = (New-Object -ComObject 'Microsoft.Update.Session')
# Query the latest 50 updates starting with the first record
$history = $session.QueryHistory("", 0, 1000) | Select-Object ResultCode, Date, Title
  
#create an array for unique HotFixes
$HotfixUnique = @()
#$HotfixUnique += ($history[0].title | Select-String -AllMatches -Pattern 'KB(\d{4,6})').Matches.Value
  
$HotFixReturnNum = @()
#$HotFixReturnNum += 0 
  
for ($i = 0; $i -lt $history.Count; $i++) {
    $check = returnHotFixID -title $history[$i].Title
    if ($HotfixUnique -like $check) {
        #Do Nothing
    }
    else {
        $HotfixUnique += $check
        $HotFixReturnNum += $i
    }
}
$FinalHotfixList = @()
  
$hotfixreturnNum | ForEach-Object {
    $HotFixItem = $history[$_]
    $Result = $HotFixItem.ResultCode
    switch ($Result) {
        1 {
            $Result = "Missing/Superseded"
        }
        2 {
            $Result = "Succeeded"
        }
        3 {
            $Result = "Succeeded With Errors"
        }
        4 {
            $Result = "Failed"
        }
        5 {
            $Result = "Canceled"
        }
    }
    $FinalHotfixList += [PSCustomObject]@{
        Result = $Result
        Date   = $HotFixItem.Date
        Title  = $HotFixItem.Title
    }    
}
$FinalHotfixList | Format-Table -AutoSize
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Drive Info"
# Load the System.Management assembly
Add-Type -AssemblyName System.Management
  
# Create a ManagementObjectSearcher to query Win32_LogicalDisk
$diskSearcher = New-Object System.Management.ManagementObjectSearcher("SELECT * FROM Win32_LogicalDisk WHERE DriveType = 3")
  
# Get the system drives
$systemDrives = $diskSearcher.Get()
  
# Loop through each drive and display its information
foreach ($drive in $systemDrives) {
    $driveLetter = $drive.DeviceID
    $driveLabel = $drive.VolumeName
    $driveSize = [math]::Round($drive.Size / 1GB, 2)
    $driveFreeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
  
    Write-Output "Drive: $driveLetter"
    Write-Output "Label: $driveLabel"
    Write-Output "Size: $driveSize GB"
    Write-Output "Free Space: $driveFreeSpace GB"
    Write-Output ""
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Antivirus Detection (attemping to read exclusions as well)"
WMIC /Node:localhost /Namespace:\\root\SecurityCenter2 Path AntiVirusProduct Get displayName
Get-ChildItem 'registry::HKLM\SOFTWARE\Microsoft\Windows Defender\Exclusions' -ErrorAction SilentlyContinue
  
  
Write-Host ""
TimeElapsed
Write-Host "== || NET ACCOUNTS Info"
net accounts
  
######################## REGISTRY SETTING CHECK ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| REGISTRY SETTINGS CHECK"
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| Audit Log Settings"
#Check audit registry
if ((Test-Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit\).Property) {
    Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit\
}
else {
    Write-Host "No Audit Log settings, no registry entry found."
}
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| Windows Event Forward (WEF) registry"
if (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager) {
    Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager
}
else {
    Write-Host "Logs are not being fowarded, no registry entry found."
}
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| LAPS Check"
if (Test-Path 'C:\Program Files\LAPS\CSE\Admpwd.dll') { Write-Host "LAPS dll found on this machine at C:\Program Files\LAPS\CSE\" -ForegroundColor Green }
elseif (Test-Path 'C:\Program Files (x86)\LAPS\CSE\Admpwd.dll' ) { Write-Host "LAPS dll found on this machine at C:\Program Files (x86)\LAPS\CSE\" -ForegroundColor Green }
else { Write-Host "LAPS dlls not found on this machine" }
if ((Get-ItemProperty HKLM:\Software\Policies\Microsoft Services\AdmPwd -ErrorAction SilentlyContinue).AdmPwdEnabled -eq 1) { Write-Host "LAPS registry key found on this machine" -ForegroundColor Green }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| WDigest Check"
$WDigest = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest).UseLogonCredential
switch ($WDigest) {
    0 { Write-Host "Value 0 found. Plain-text Passwords are not stored in LSASS" }
    1 { Write-Host "Value 1 found. Plain-text Passwords may be stored in LSASS" -ForegroundColor red }
    Default { Write-Host "The system was unable to find the specified registry value: UesLogonCredential" }
}
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| LSA Protection Check"
$RunAsPPL = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\LSA).RunAsPPL
$RunAsPPLBoot = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\LSA).RunAsPPLBoot
switch ($RunAsPPL) {
    2 { Write-Host "RunAsPPL: 2. Enabled without UEFI Lock" }
    1 { Write-Host "RunAsPPL: 1. Enabled with UEFI Lock" }
    0 { Write-Host "RunAsPPL: 0. LSA Protection Disabled. Try mimikatz." -ForegroundColor red }
    Default { "The system was unable to find the specified registry value: RunAsPPL / RunAsPPLBoot" }
}
if ($RunAsPPLBoot) { Write-Host "RunAsPPLBoot: $RunAsPPLBoot" }
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| Credential Guard Check"
$LsaCfgFlags = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\LSA).LsaCfgFlags
switch ($LsaCfgFlags) {
    2 { Write-Host "LsaCfgFlags 2. Enabled without UEFI Lock" }
    1 { Write-Host "LsaCfgFlags 1. Enabled with UEFI Lock" }
    0 { Write-Host "LsaCfgFlags 0. LsaCfgFlags Disabled." -ForegroundColor red }
    Default { "The system was unable to find the specified registry value: LsaCfgFlags" }
}
  
   
Write-Host ""
TimeElapsed
Write-Host "==|| Cached WinLogon Credentials Check"
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon") {
    (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "CACHEDLOGONSCOUNT").CACHEDLOGONSCOUNT
    Write-Host "However, only the SYSTEM user can view the credentials here: HKEY_LOCAL_MACHINE\SECURITY\Cache"
    Write-Host "Or, using mimikatz lsadump::cache"
}
  
Write-Host ""
TimeElapsed
Write-Host "==|| Additonal Winlogon Credentials Check"
  
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").DefaultDomainName
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").DefaultUserName
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").DefaultPassword
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").AltDefaultDomainName
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").AltDefaultUserName
  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").AltDefaultPassword
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| RDCMan Settings Check"
  
if (Test-Path "$env:USERPROFILE\appdata\Local\Microsoft\Remote Desktop Connection Manager\RDCMan.settings") {
    Write-Host "RDCMan Settings Found at: $($env:USERPROFILE)\appdata\Local\Microsoft\Remote Desktop Connection Manager\RDCMan.settings" -ForegroundColor Red
}
else { write-host "No RCDMan.Settings found." }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| RDP Saved Connections Check"
  
Write-Host "HK_Users"
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
Get-ChildItem HKU:\ -ErrorAction SilentlyContinue | ForEach-Object {
    # get the SID from output
    $HKUSID = $_.Name.Replace('HKEY_USERS\', "")
    if (test-path "registry::HKEY_USERS\$HKUSID\Software\Microsoft\Terminal Server Client\Default") {
        Write-Host "Server Found: $((Get-ItemProperty "registry::HKEY_USERS\$HKUSID\Software\Microsoft\Terminal Server Client\Default" -name MRU0).MRU0)"
    }
    else { Write-Host "Not found for $($_.Name)" }
}
  
Write-Host "HKCU"
if (test-path "registry::HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default") {
    write-host "Server Found: $((Get-ItemProperty "registry::HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default" -name MRU0).MRU0)"
}
else { Write-Host "Terminal Server Client not found in HCKU" }
  
Write-Host ""
TimeElapsed
Write-Host "==|| Putty Stored Credentials Check"
  
if (Test-Path HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions) {
    Get-ChildItem HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions | ForEach-Object {
        $RegKeyName = Split-Path $_.Name -Leaf
        Write-Host "Key: $RegKeyName"
        @("HostName", "PortNumber", "UserName", "PublicKeyFile", "PortForwardings", "ConnectionSharing", "ProxyUsername", "ProxyPassword") | ForEach-Object {
            write-host "$_ :"
            write-host "$((Get-ItemProperty  HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions\$RegKeyName).$_)"
        }
    }
}
else { write-host "No putty credentials found in HKCU:\SOFTWARE\SimonTatham\PuTTY\Sessions" }
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| SSH Key Checks"
Write-Host ""
TimeElapsed
Write-Host "==|| If found:"
Write-Host ""
TimeElapsed
Write-Host "==|| Checking Putty SSH KNOWN HOSTS"
if (Test-Path HKCU:\Software\SimonTatham\PuTTY\SshHostKeys) { 
    write-host "$((Get-Item -path HKCU:\Software\SimonTatham\PuTTY\SshHostKeys).Property)"
}
else { Write-host "No putty ssh keys found" }
  
Write-Host ""
TimeElapsed
Write-Host "==|| Checking for OpenSSH Keys"
if (Test-Path HKCU:\Software\OpenSSH\Agent\Keys) { Write-Host "OpenSSH keys found. Try this for decryption: https://github.com/ropnop/windows_sshagent_extract" -ForegroundColor Yellow }
else { Write-Host "No OpenSSH Keys found." }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Checking for WinVNC Passwords"
if ( Test-Path "HKCU:\Software\ORL\WinVNC3\Password") { Write-host " WinVNC found at HKCU:\Software\ORL\WinVNC3\Password" }else { Write-Host "No WinVNC found." }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Checking for SNMP Passwords"
if ( Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP" ) { Write-host "SNPM Key found at HKLM:\SYSTEM\CurrentControlSet\Services\SNMP" }else { Write-host "No SNPM found." }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Checking for TightVNC Passwords"
if ( Test-Path "HKCU:\Software\TightVNC\Server") { write-host "TightVNC key found at HKCU:\Software\TightVNC\Server" }else { write-host "No TightVNC found." }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| UAC Settings"
if ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA -eq 1) {
    Write-Host "EnableLUA is equal to 1. Part or all of the UAC components are on."
}
else { Write-Host "EnableLUA value not equal to 1" }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Recently Run Commands (WIN+R)"
  
Get-ChildItem HKU:\ -ErrorAction SilentlyContinue | ForEach-Object {
    # get the SID from output
    $HKUSID = $_.Name.Replace('HKEY_USERS\', "")
    $property = (Get-Item "HKU:\$_\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -ErrorAction SilentlyContinue).Property
    $HKUSID | ForEach-Object {
        if (test-path "HKU:\$_\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU") {
            Write-Host "==|| HKU Recently Run Commands"
            foreach ($p in $property) {
                Write-Host "$((Get-Item "HKU:\$_\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"-ErrorAction SilentlyContinue).getValue($p))" 
            }
        }
    }
}
  
Write-Host ""
TimeElapsed
Write-Host "==|| HKCU Recently Run Commands"
$property = (Get-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -ErrorAction SilentlyContinue).Property
foreach ($p in $property) {
    Write-Host "$((Get-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"-ErrorAction SilentlyContinue).getValue($p))"
}
  
Write-Host ""
TimeElapsed
Write-Host "==|| Always Install Elevated Check"
   
Write-Host "Checking Windows Installer Registry (will populate if the key exists)"
if ((Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue).AlwaysInstallElevated -eq 1) {
    Write-Host "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer).AlwaysInstallElevated = 1" -ForegroundColor red
    Write-Host "Try msfvenom msi package to escalate" -ForegroundColor red
}
   
if ((Get-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue).AlwaysInstallElevated -eq 1) { 
    Write-Host "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer).AlwaysInstallElevated = 1" -ForegroundColor red
    Write-Host "Try msfvenom msi package to escalate" -ForegroundColor red
}
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| PowerShell Info"
  
  (Get-ItemProperty registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine).PowerShellVersion | ForEach-Object {
    Write-Host "PowerShell $_ available"
}
  (Get-ItemProperty registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine).PowerShellVersion | ForEach-Object {
    Write-Host  "PowerShell $_ available"
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| PowerShell Registry Transcript Check"
  
if (Test-Path HKCU:\Software\Policies\Microsoft\Windows\PowerShell\Transcription) {
    Get-Item HKCU:\Software\Policies\Microsoft\Windows\PowerShell\Transcription
}
if (Test-Path HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription) {
    Get-Item HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription
}
if (Test-Path HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\Transcription) {
    Get-Item HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\Transcription
}
if (Test-Path HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\Transcription) {
    Get-Item HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\Transcription
}
   
  
Write-Host ""
TimeElapsed
Write-Host "==|| PowerShell Module Log Check"
if (Test-Path HKCU:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging) {
    Get-Item HKCU:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging
}
if (Test-Path HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging) {
    Get-Item HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging
}
if (Test-Path HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging) {
    Get-Item HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging
}
if (Test-Path HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging) {
    Get-Item HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging
}
   
  
Write-Host ""
TimeElapsed
Write-Host "==|| PowerShell Script Block Log Check"
   
if ( Test-Path HKCU:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging) {
    Get-Item HKCU:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
}
if ( Test-Path HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging) {
    Get-Item HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
}
if ( Test-Path HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging) {
    Get-Item HKCU:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
}
if ( Test-Path HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging) {
    Get-Item HKLM:\Wow6432Node\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| WSUS check for http and UseWAServer = 1, if true, might be vulnerable to exploit"
if (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate) {
    Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
}
if ((Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name "USEWUServer" -ErrorAction SilentlyContinue).UseWUServer) {
    (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name "USEWUServer").UseWUServer
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Internet Settings HKCU / HKLM"
  
$property = (Get-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).Property
foreach ($p in $property) {
    Write-Host "$p - $((Get-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"-ErrorAction SilentlyContinue).getValue($p))"
}
   
$property = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).Property
foreach ($p in $property) {
    Write-Host "$p - $((Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"-ErrorAction SilentlyContinue).getValue($p))"
}
  
  
  
######################## PROCESS INFORMATION ########################
Write-Host ""
TimeElapsed
Write-Host "========= || RUNNING PROCESSES"
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| Checking user permissions on running processes"
Get-Process | Select-Object Path -Unique | ForEach-Object { Start-ACLCheck -Target $_.path }
  
  
#TODO, vulnerable system process running that we have access to. 
Write-Host ""
TimeElapsed
Write-Host "==|| System processes"
Start-process tasklist -argumentList '/v /fi "username eq system"' -wait -NoNewWindow
  
  
######################## SERVICES ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| SERVICE path vulnerable check"
Write-Host "Checking for vulnerable service .exe"
# Gathers all services running and stopped, based on .exe and shows the AccessControlList
$UniqueServices = @{}
Get-WmiObject Win32_Service | Where-Object { $_.PathName -like '*.exe*' } | ForEach-Object {
    $Path = ($_.PathName -split '(?<=\.exe\b)')[0].Trim('"')
    $UniqueServices[$Path] = $_.Name
}
foreach ( $h in ($UniqueServices | Select-Object -Unique).GetEnumerator()) {
    Start-ACLCheck -Target $h.Name -ServiceName $h.Value
}
  
  
######################## UNQUOTED SERVICE PATH CHECK ############
Write-Host ""
TimeElapsed
Write-Host "=========|| Checking for Unquoted Service Paths"
  
UnquotedServicePathCheck
  
  
######################## REGISTRY SERVICE CONFIGURATION CHECK ###
Write-Host ""
TimeElapsed
Write-Host "==|| Checking Service Registry Permissions"
Write-host "This will take some time."
  
Get-ChildItem 'HKLM:\System\CurrentControlSet\services\' | ForEach-Object {
    $target = $_.Name.Replace("HKEY_LOCAL_MACHINE", "hklm:")
    Start-aclcheck -Target $target
}
  
  
######################## SCHEDULED TASKS ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| SCHEDULED TASKS vulnerable check"
#Scheduled tasks audit 
  
Write-Host ""
TimeElapsed
Write-Host "==|| Testing access to c:\windows\system32\tasks"
if (Get-ChildItem "c:\windows\system32\tasks" -ErrorAction SilentlyContinue) {
    Write-Host "Access confirmed, may need futher investigation"
    Get-ChildItem "c:\windows\system32\tasks"
}
else {
    Write-Host "No admin access to scheduled tasks folder."
    Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft*" } | ForEach-Object {
        $Actions = $_.Actions.Execute
        if ($Actions -ne $null) {
            foreach ($a in $actions) {
                if ($a -like "%windir%*") { $a = $a.replace("%windir%", $Env:windir) }
                elseif ($a -like "%SystemRoot%*") { $a = $a.replace("%SystemRoot%", $Env:windir) }
                elseif ($a -like "%localappdata%*") { $a = $a.replace("%localappdata%", "$env:UserProfile\appdata\local") }
                elseif ($a -like "%appdata%*") { $a = $a.replace("%localappdata%", $env:Appdata) }
                $a = $a.Replace('"', '')
                Start-ACLCheck -Target $a
                Write-host "`n"
                Write-Host "TaskName: $($_.TaskName)"
                Write-Host "-------------"
                [pscustomobject]@{
                    LastResult = $(($_ | Get-ScheduledTaskInfo).LastTaskResult)
                    NextRun    = $(($_ | Get-ScheduledTaskInfo).NextRunTime)
                    Status     = $_.State
                    Command    = $_.Actions.execute
                    Arguments  = $_.Actions.Arguments 
                } | write-host
            } 
        }
    }
}
  
  
######################## STARTUP APPLIICATIONS #########################
Write-Host ""
TimeElapsed
Write-Host "=========|| STARTUP APPLICATIONS Vulnerable Check"
"Check if you can modify any binary that is going to be executed by admin or if you can impersonate a not found binary"
  
@("C:\Documents and Settings\All Users\Start Menu\Programs\Startup",
    "C:\Documents and Settings\%username%\Start Menu\Programs\Startup", 
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup", 
    "$env:Appdata\Microsoft\Windows\Start Menu\Programs\Startup") | ForEach-Object {
    if (Test-Path $_) {
        # CheckACL of each top folder then each sub folder/file
        Start-ACLCheck $_
        Get-ChildItem -Recurse -Force -Path $_ | ForEach-Object {
            $SubItem = $_.FullName
            if (test-path $SubItem) { 
                Start-ACLCheck -Target $SubItem
            }
        }
    }
}
Write-Host ""
TimeElapsed
Write-Host "==|| STARTUP APPS Registry Check"
  
@("registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Run",
    "registry::HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Run",
    "registry::HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce") | ForEach-Object {
    # CheckACL of each Property Value found
    $ROPath = $_
    (Get-Item $_) | ForEach-Object {
        $ROProperty = $_.property
        $ROProperty | ForEach-Object {
            Start-ACLCheck ((Get-ItemProperty -Path $ROPath).$_ -split '(?<=\.exe\b)')[0].Trim('"')
        }
    }
}
  
#schtasks /query /fo TABLE /nh | findstr /v /i "disable deshab informa"
  
  
######################## INSTALLED APPLICATIONS ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| INSTALLED APPLICATIONS"
Write-Host "Generating list of installed applications"
  
Get-CimInstance -class win32_Product | Select-Object Name, Version | 
ForEach-Object {
    Write-Host $("{0} : {1}" -f $_.Name, $_.Version)  
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| LOOKING FOR BASH.EXE"
Get-ChildItem C:\Windows\WinSxS\ -Filter "amd64_microsoft-windows-lxss-bash*" | ForEach-Object {
    Write-Host $((Get-ChildItem $_.FullName -Recurse -Filter "*bash.exe*").FullName)
}
@("bash.exe", "wsl.exe") | ForEach-Object { Write-Host $((Get-ChildItem C:\Windows\System32\ -Filter $_).FullName) }
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| LOOKING FOR SCCM CLIENT"
$result = Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_Application -Property * -ErrorAction SilentlyContinue | Select-Object Name, SoftwareVersion
if ($result) { $result }
elseif (Test-Path 'C:\Windows\CCM\SCClient.exe') { Write-Host "SCCM Client found at C:\Windows\CCM\SCClient.exe" -ForegroundColor Cyan }
else { Write-Host "Not Installed." }
  
  
######################## NETWORK INFORMATION ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| NETWORK INFORMATION"
  
Write-Host ""
TimeElapsed
Write-Host "==|| HOSTS FILE"
  
Write-Host "Get content of etc\hosts file"
Get-Content "c:\windows\system32\drivers\etc\hosts"
  
Write-Host ""
TimeElapsed
Write-Host "==|| IP INFORMATION"
  
# Get all v4 and v6 addresses
Write-Host ""
TimeElapsed
Write-Host "==|| Ipconfig ALL"
start-process ipconfig.exe -ArgumentList "/all" -Wait -NoNewWindow
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| DNS Cache"
ipconfig /displaydns | select-string "Record" | ForEach-Object { Write-Host $('{ 0 }' -f $_) }
   
Write-Host ""
TimeElapsed
Write-Host "==|| LISTENING PORTS"
  
# running netstat as powershell is too slow to print to console
start-process NETSTAT.EXE -argumentList "-ano" -Wait -NoNewWindow
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| ARP Table"
  
# Arp table info
Start-process arp -argumentList "-A" -Wait -NoNewWindow
  
Write-Host ""
TimeElapsed
Write-Host "==|| Routes"
  
# Route info
start-process route -argumentList "print" -Wait -NoNewWindow
  
Write-Host ""
TimeElapsed
Write-Host "==|| Network Adapter info"
  
# Network Adapter info
Get-NetAdapter | ForEach-Object { 
    write-host "----------"
    write-host $_.Name
    write-host $_.InterfaceDescription
    write-host $_.ifIndex
    write-host $_.Status
    write-host $_.MacAddress
    write-host "----------"
} 
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Checking for WiFi passwords"
# Select all wifi adapters, then pull the SSID along with the password
  
  ((netsh.exe wlan show profiles) -match '\s { 2, }:\s').replace("    All User Profile     : ", "") | ForEach-Object {
    netsh wlan show profile name="$_" key=clear 
}
  
  
Write-Host ""
TimeElapsed
Write-Host "==|| Enabled firewall rules - displaying command only - it can overwrite the display buffer"
Write-Host "==|| show all rules with: netsh advfirewall firewall show rule dir=in name=all"
# Route info
  
Write-Host ""
TimeElapsed
Write-Host "==|| SMB SHARES"
Write-Host "Will enumerate SMB Shares and Access if any are available" 
  
Get-SmbShare | Get-SmbShareAccess | ForEach-Object {
    $SMBShareObject = $_
    whoami.exe /groups /fo csv | ConvertFrom-Csv | Select-Object -ExpandProperty 'group name' | ForEach-Object {
        if ($SMBShareObject.AccountName -like $_ -and ($SMBShareObject.AccessRight -like "Full" -or "Change") -and $SMBShareObject.AccessControlType -like "Allow" ) {
            Write-Host -ForegroundColor red "$($SMBShareObject.AccountName) has $($SMBShareObject.AccessRight) to $($SMBShareObject.Name)"
        }
    }
}
  
  
######################## USER INFO ########################
Write-Host ""
TimeElapsed
Write-Host "=========|| USER INFO"
Write-Host "== || Generating List of all Administrators, Users and Backup Operators (if any exist)"
  
@("ADMINISTRATORS", "USERS") | ForEach-Object {
    Write-Host $_
    Write-Host "-------"
    Start-process net -ArgumentList "localgroup $_" -Wait -NoNewWindow
}
Write-Host "BACKUP OPERATORS"
Write-Host "-------"
start-process net -ArgumentList 'localgroup "Backup Operators"' -wait -NoNewWindow
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| USER DIRECTORY ACCESS CHECK"
Get-ChildItem C:\Users\* | ForEach-Object {
    if (Get-ChildItem $_.FullName -ErrorAction SilentlyContinue) {
        Write-Host -ForegroundColor red "Read Access to $($_.FullName)"
    }
}
  
#Whoami 
Write-Host ""
TimeElapsed
Write-Host "=========|| WHOAMI INFO"
Write-Host ""
TimeElapsed
Write-Host "==|| Check if you are inside the Administrators group or if you have enabled any token that can be use to escalate privileges like SeImpersonatePrivilege, SeAssignPrimaryPrivilege, SeTcbPrivilege, SeBackupPrivilege, SeRestorePrivilege, SeCreateTokenPrivilege, SeLoadDriverPrivilege, SeTakeOwnershipPrivilege, SeDebbugPrivilege"
start-process whoami.exe -ArgumentList "/all" -wait -NoNewWindow
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| Cloud Credentials Check"
$Users = (Get-ChildItem C:\Users).Name
$CCreds = @(".aws\credentials",
    "AppData\Roaming\gcloud\credentials.db",
    "AppData\Roaming\gcloud\legacy_credentials",
    "AppData\Roaming\gcloud\access_tokens.db",
    ".azure\accessTokens.json",
    ".azure\azureProfile.json") 
foreach ($u in $users) {
    $CCreds | ForEach-Object {
        if (Test-Path "c:\$u\$_") { Write-Host "$_ found!" -ForegroundColor Red }
    }
}
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| APPcmd Check"
if (Test-Path ("$Env:SystemRoot\System32\inetsrv\appcmd.exe")) {
    Write-Host "$Env:SystemRoot\System32\inetsrv\appcmd.exe exists!" -ForegroundColor Red
}
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| OpenVPN Credentials Check"
  
$keys = Get-ChildItem "HKCU:\Software\OpenVPN-GUI\configs" -ErrorAction SilentlyContinue
if ($Keys) {
    Add-Type -AssemblyName System.Security
    $items = $keys | ForEach-Object { Get-ItemProperty $_.PsPath }
    foreach ($item in $items) {
        $encryptedbytes = $item.'auth-data'
        $entropy = $item.'entropy'
        $entropy = $entropy[0..(($entropy.Length) - 2)]
  
        $decryptedbytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $encryptedBytes, 
            $entropy, 
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
   
        Write-Host ([System.Text.Encoding]::Unicode.GetString($decryptedbytes))
    }
}
  
  
Write-Host ""
TimeElapsed
Write-Host "=========|| PowerShell History (Password Search Only)"
  
Write-Host "=|| PowerShell Console History"
Write-Host "=|| To see all history, run this command: Get-Content (Get-PSReadlineOption).HistorySavePath"
Write-Host $(Get-Content (Get-PSReadLineOption).HistorySavePath | Select-String pa)
  
Write-Host "=|| AppData PSReadline Console History "
Write-Host "=|| To see all history, run this command: Get-Content $env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
Write-Host $(Get-Content "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" | Select-String pa)
  
  
Write-Host "=|| PowesRhell default transrcipt history check "
if (Test-Path $env:SystemDrive\transcripts\) { "Default transcripts found at $($env:SystemDrive)\transcripts\" }
  
  

