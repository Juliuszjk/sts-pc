<#
    PC PERIODIC MAINTENANCE - FULL AUTOMATION EDITION (SEQUENTIAL FORCE INSTALL)
    Execution: irm https://raw.githubusercontent.com/Juliuszjk/sts-pc/refs/heads/main/Pc-update.ps1 | iex
#>

$scriptUrl = "https://raw.githubusercontent.com/Juliuszjk/sts-pc/refs/heads/main/Pc-update.ps1"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$scriptUrl' | iex`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'SilentlyContinue'

$items = @(
    @{ Id=3;  Desc="PC Data (Name, OS, Non-Admins)" }
    @{ Id=5;  Desc="Disable Smart App Control" }
    @{ Id=7;  Desc="Drive Type" }
    @{ Id=8;  Desc="Free Drive Space (%)" }
    @{ Id=12; Desc="Remote Desktop (Everyone + No NLA)" }
    @{ Id=22; Desc="Bitdefender Open" }
    @{ Id=26; Desc="BitLocker Status" }
    @{ Id=20; Desc="Java (Copy from USB & Set Env)" }
    @{ Id=25; Desc="TeamViewer QS (Auto-Copy to Public Desktop)" }
    @{ Id=16; Desc="Firefox / Chrome (Force Install)" }
    @{ Id=18; Desc="Adobe AIR (Force Install)" }
    @{ Id=19; Desc="7-Zip (Force Install)" }
    @{ Id=30; Desc="Adobe Reader (Force Install)" }
    @{ Id=32; Desc="Copy Arcabit to Desktop (Keep)" }
)

$syncHash = [hashtable]::Synchronized(@{
    Status   = @{}
    Detail   = @{}
    Current  = "Waiting to start..."
    IsDone   = $false
    Total    = $items.Count
    Finished = 0
})
foreach ($item in $items) { $syncHash.Status[$item.Id] = "PENDING"; $syncHash.Detail[$item.Id] = "" }

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "PC Periodic Maintenance - Full Automation Edition"
$mainForm.Size = New-Object System.Drawing.Size(900,700)
$mainForm.StartPosition = "CenterScreen"
$mainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lblUnit = New-Object System.Windows.Forms.Label
$lblUnit.Text = "Target Unit:"
$lblUnit.Location = New-Object System.Drawing.Point(10,15)
$lblUnit.AutoSize = $true
$mainForm.Controls.Add($lblUnit)

$txtUnit = New-Object System.Windows.Forms.TextBox
$txtUnit.Location = New-Object System.Drawing.Point(90,12)
$txtUnit.Width = 200
$mainForm.Controls.Add($txtUnit)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Maintenance"
$btnStart.Location = New-Object System.Drawing.Point(700,10)
$btnStart.Width = 170
$btnStart.Height = 30
$btnStart.BackColor = [System.Drawing.Color]::LightGreen
$mainForm.Controls.Add($btnStart)

$lblQuick = New-Object System.Windows.Forms.Label
$lblQuick.Text = "Quick Launch:"
$lblQuick.Location = New-Object System.Drawing.Point(10,50)
$lblQuick.AutoSize = $true
$mainForm.Controls.Add($lblQuick)

$btnBD = New-Object System.Windows.Forms.Button
$btnBD.Text = "Bitdefender Endpoint Security Tools"
$btnBD.Location = New-Object System.Drawing.Point(140,45)
$btnBD.Width = 250
$btnBD.Add_Click({
    Start-Process "C:\Program Files\Bitdefender\Endpoint Security\ui\EPSecurityConsoleUI.exe" -ErrorAction SilentlyContinue
})
$mainForm.Controls.Add($btnBD)

$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Text = "Waiting to start..."
$lblCurrent.Location = New-Object System.Drawing.Point(10,85)
$lblCurrent.AutoSize = $true
$lblCurrent.ForeColor = [System.Drawing.Color]::Blue
$lblCurrent.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$mainForm.Controls.Add($lblCurrent)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,110)
$progressBar.Width = 860
$progressBar.Height = 20
$progressBar.Maximum = $items.Count
$mainForm.Controls.Add($progressBar)

$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10,140)
$dataGrid.Size = New-Object System.Drawing.Size(860,480)
$dataGrid.ReadOnly = $true
$dataGrid.AllowUserToAddRows = $false
$dataGrid.AllowUserToDeleteRows = $false
$dataGrid.AllowUserToResizeRows = $false
$dataGrid.RowHeadersVisible = $false
$dataGrid.AutoSizeColumnsMode = "Fill"
$dataGrid.SelectionMode = "FullRowSelect"
$dataGrid.Columns.Add("Id","Id") | Out-Null
$dataGrid.Columns.Add("Desc","Description") | Out-Null
$dataGrid.Columns.Add("Status","Status") | Out-Null
$dataGrid.Columns.Add("Detail","Details") | Out-Null
$dataGrid.Columns["Id"].FillWeight = 8
$dataGrid.Columns["Desc"].FillWeight = 35
$dataGrid.Columns["Status"].FillWeight = 15
$dataGrid.Columns["Detail"].FillWeight = 42

foreach ($item in $items) {
    $dataGrid.Rows.Add($item.Id, $item.Desc, "PENDING", "") | Out-Null
}
$mainForm.Controls.Add($dataGrid)

$dataGrid.Add_CellDoubleClick({
    param($sender,$eventArgs)
    if ($eventArgs.RowIndex -lt 0) { return }
    $id = [int]$dataGrid.Rows[$eventArgs.RowIndex].Cells["Id"].Value
    switch ($id) {
        22 { Start-Process "C:\Program Files\Bitdefender\Endpoint Security\ui\EPSecurityConsoleUI.exe" -ErrorAction SilentlyContinue }
        20 {
            $javaBase = "C:\Program Files\Java"
            if (Test-Path $javaBase) {
                $latestJava = Get-ChildItem -Path $javaBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
                if ($latestJava) {
                    $jPath = $latestJava.FullName
                    $bPath = "$jPath\bin"
                    
                    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jPath, "Machine")
                    $mPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                    
                    if ($mPath -notmatch [regex]::Escape($bPath)) {
                        [Environment]::SetEnvironmentVariable("Path", "$mPath;$bPath", "Machine")
                    }
                    
                    [System.Windows.Forms.MessageBox]::Show("Java configured to $jPath.", "Success")
                }
            }
        }
        default {
            $detail = $dataGrid.Rows[$eventArgs.RowIndex].Cells["Detail"].Value
            [System.Windows.Forms.MessageBox]::Show($detail, "Item $id Details")
        }
    }
})

$lblFooter = New-Object System.Windows.Forms.Label
$lblFooter.Text = "Ready."
$lblFooter.Location = New-Object System.Drawing.Point(10,630)
$lblFooter.AutoSize = $true
$mainForm.Controls.Add($lblFooter)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export CSV Report"
$btnExport.Location = New-Object System.Drawing.Point(700,625)
$btnExport.Width = 170
$btnExport.Add_Click({
    $exportPath = "$env:USERPROFILE\Desktop\Maintenance_Report_$env:COMPUTERNAME.csv"
    $exportRows = foreach ($row in $dataGrid.Rows) {
        [pscustomobject]@{
            Id=$row.Cells["Id"].Value; Desc=$row.Cells["Desc"].Value
            Status=$row.Cells["Status"].Value; Detail=$row.Cells["Detail"].Value
        }
    }
    $exportRows | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Saved to: $exportPath","Export")
})
$mainForm.Controls.Add($btnExport)

$workerScriptBlock = {
    param($sync, $targetUnit)

    function Update-State($id, $status, $detail = "") {
        $sync.Status[$id] = $status
        $sync.Detail[$id] = $detail
        $sync.Finished++
    }
    function Update-Current($text) { $sync.Current = $text }

    $ErrorActionPreference = 'SilentlyContinue'
    
    $script:localInstalDir = "$env:USERPROFILE\Desktop\INSTALKI"
    $script:filesCopied = $false
    $script:usbDriveLetter = $null

    function Ensure-USB {
        if ($script:usbDriveLetter) { return $true }
        Update-Current "Checking for USB drive labeled 'SERWIS'..."
        while (-not $script:usbDriveLetter) {
            $drive = Get-Volume | Where-Object { $_.FileSystemLabel -match "SERWIS" } | Select-Object -ExpandProperty DriveLetter
            if ($drive) { $script:usbDriveLetter = $drive; break }
            Start-Sleep -Seconds 2
            if ($sync.IsDone) { return $false }
        }
        return $true
    }

    function Ensure-InstallFiles {
        if ($script:filesCopied) { return $true }
        if (-not (Ensure-USB)) { return $false }

        $usbPath = "$($script:usbDriveLetter):\INSTALKI"
        if (-not (Test-Path $usbPath)) {
            Update-Current "Found SERWIS drive, but INSTALKI folder is missing!"
            Start-Sleep -Seconds 3
            return $false
        }

        Update-Current "Copying files from USB ($usbPath) to local drive..."
        try {
            Copy-Item -Path $usbPath -Destination $script:localInstalDir -Recurse -Force
            $script:filesCopied = $true
            return $true
        } catch {
            return $false
        }
    }

    Update-Current "Checking PC Data & Accounts..."
    try {
        $pcName = $env:COMPUTERNAME
        $osInfo = Get-CimInstance Win32_OperatingSystem
        
        $adminSid = "S-1-5-32-544"
        $adminGroupName = (Get-LocalGroup | Where-Object { $_.SID -like $adminSid }).Name
        $adminMembers = Get-LocalGroupMember -Group $adminGroupName | Select-Object -ExpandProperty Name
        $nonAdminUsers = Get-LocalUser | Where-Object { $_.Enabled -and ($adminMembers -notcontains "$pcName\$($_.Name)") -and ($adminMembers -notcontains $_.Name) }
        $nonAdminNames = ($nonAdminUsers.Name) -join ', '
        if ([string]::IsNullOrEmpty($nonAdminNames)) { $nonAdminNames = "None found" }
        
        Update-State 3 "OK" "Name: $pcName | $($osInfo.Caption) | Unit: $targetUnit | Non-Admins: $nonAdminNames"
    } catch { Update-State 3 "ERROR" $_.Exception.Message }

    Update-Current "Disabling Smart App Control..."
    try {
        $sacPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        $sacState = "Key Missing"
        if (Test-Path $sacPath) {
            $sacValue = (Get-ItemProperty -Path $sacPath -Name VerifiedAndReputablePolicyState -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
            if ($sacValue -ne 0) {
                New-ItemProperty -Path $sacPath -Name VerifiedAndReputablePolicyState -PropertyType DWord -Value 0 -Force | Out-Null
                $sacState = "Disabled (requires reboot)"
            } else { $sacState = "Already Disabled" }
        }
        Update-State 5 "OK" "SAC: $sacState"
    } catch { Update-State 5 "ERROR" $_.Exception.Message }

    Update-Current "Checking Drive Type..."
    $physicalDrives = Get-PhysicalDisk | Select-Object DeviceId, MediaType
    Update-State 7 "OK" (($physicalDrives.MediaType | Sort-Object -Unique) -join "+")

    Update-Current "Checking Free Drive Space..."
    $sysVolume = Get-Volume -DriveLetter C
    $freePercent = [math]::Round(($sysVolume.SizeRemaining / $sysVolume.Size) * 100, 1)
    Update-State 8 "OK" "Free space: $freePercent%"

    Update-Current "Configuring Remote Desktop..."
    try {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0
        
        $gpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
        if (-not (Test-Path $gpoPath)) { New-Item -Path $gpoPath -Force | Out-Null }
        Set-ItemProperty -Path $gpoPath -Name "UserAuthentication" -Value 0
        
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        Enable-NetFirewallRule -DisplayGroup "Pulpit zdalny" -ErrorAction SilentlyContinue

        $rdpSid = "S-1-5-32-555"
        $rdpGroupName = (Get-LocalGroup | Where-Object { $_.SID -like $rdpSid }).Name
        $everyoneSidObj = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
        $everyoneAccountName = $everyoneSidObj.Translate([System.Security.Principal.NTAccount]).Value
        Add-LocalGroupMember -Group $rdpGroupName -Member $everyoneAccountName -ErrorAction SilentlyContinue

        Update-State 12 "OK" "RDP Enabled | NLA Disabled (GPO Enforced) | Everyone Allowed"
    } catch { Update-State 12 "ERROR" $_.Exception.Message }

    Update-Current "Checking BitLocker..."
    $bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    if ($bitlocker) {
        if ($bitlocker.ProtectionStatus -eq 'On') { Update-State 26 "OK" "Protection ON: $($bitlocker.VolumeStatus)" }
        else { Update-State 26 "WARN" "Protection OFF or Unconfigured" }
    } else { Update-State 26 "WARN" "BitLocker unavailable" }

    Update-Current "Opening Bitdefender..."
    $bdExe = "C:\Program Files\Bitdefender\Endpoint Security\ui\EPSecurityConsoleUI.exe"
    if (Test-Path $bdExe) { 
        Start-Process $bdExe
        Update-State 22 "OK" "Bitdefender Opened" 
    } else { 
        Update-State 22 "WARN" "Bitdefender not found at exact path" 
    }

    # ==========================
    # JAVA (COPY & CONFIGURE)
    # ==========================
    Update-Current "Copying and Checking Java..."
    try {
        if (Ensure-USB) {
            $usbJavaPath = "$($script:usbDriveLetter):\Java"
            $localJavaBase = "C:\Program Files\Java"
            
            if (Test-Path $usbJavaPath) {
                if (-not (Test-Path $localJavaBase)) { New-Item -ItemType Directory -Path $localJavaBase -Force | Out-Null }
                Copy-Item -Path "$usbJavaPath\*" -Destination $localJavaBase -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        $javaBase = "C:\Program Files\Java"
        if (Test-Path $javaBase) {
            $latestJava = Get-ChildItem -Path $javaBase -Directory | Sort-Object Name -Descending | Select-Object -First 1
            if ($latestJava) {
                $jPath = $latestJava.FullName
                $bPath = "$jPath\bin"
                
                [Environment]::SetEnvironmentVariable("JAVA_HOME", $jPath, "Machine")
                $mPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                
                if ($mPath -notmatch [regex]::Escape($bPath)) {
                    [Environment]::SetEnvironmentVariable("Path", "$mPath;$bPath", "Machine")
                }
                Update-State 20 "OK" "Copied from USB & Configured: $jPath"
            } else {
                Update-State 20 "WARN" "Folder empty. Copy manually and double-click."
            }
        } else {
            Update-State 20 "WARN" "No Java found. Copy manually and double-click."
        }
    } catch { Update-State 20 "ERROR" $_.Exception.Message }

    Update-Current "Force checking TeamViewer QS..."
    $pubDesktop = "$env:PUBLIC\Desktop"
    $userDesktop = "$env:USERPROFILE\Desktop"
    
    $tvPub = Get-ChildItem -Path $pubDesktop -Filter "TeamViewerQS*.exe" -ErrorAction SilentlyContinue
    if ($tvPub) {
        if ($tvPub.Count -gt 1) {
            $tvPub | Sort-Object LastWriteTime -Descending | Select-Object -Skip 1 | Remove-Item -Force
        }
        Update-State 25 "OK" "Found on Public Desktop"
    } else {
        $tvUser = Get-ChildItem -Path $userDesktop -Filter "TeamViewerQS*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($tvUser) {
            Move-Item -Path $tvUser.FullName -Destination "$pubDesktop\TeamViewerQS.exe" -Force
            Update-State 25 "ACTION" "Moved from User to Public Desktop"
        } else {
            if (Ensure-InstallFiles) {
                $tvSource = Get-ChildItem -Path $script:localInstalDir -Filter "TeamViewer*.exe" | Select-Object -First 1
                if ($tvSource) {
                    Copy-Item -Path $tvSource.FullName -Destination "$pubDesktop\TeamViewerQS.exe" -Force
                    Update-State 25 "ACTION" "Copied from USB to Public Desktop"
                } else { 
                    Update-State 25 "ERROR" "TeamViewer installer not found in USB" 
                }
            } else { 
                Update-State 25 "WARN" "Awaiting USB for TeamViewer" 
            }
        }
    }

    Update-Current "Force installing Browsers..."
    $browserResults = @()
    $hasBrowserIssues = $false
    
    if (Ensure-InstallFiles) {
        $ffExe = Get-ChildItem -Path $script:localInstalDir -Filter "Firefox*.exe" | Select-Object -First 1
        if ($ffExe) {
            Start-Process $ffExe.FullName -ArgumentList "/S" -Wait -NoNewWindow
            $browserResults += "Firefox: Installed"
        } else { $browserResults += "Firefox: Missing file"; $hasBrowserIssues = $true }

        $chrExe = Get-ChildItem -Path $script:localInstalDir -Filter "Chrome*.exe" | Select-Object -First 1
        if ($chrExe) {
            Start-Process $chrExe.FullName -ArgumentList "/silent /install" -Wait -NoNewWindow
            $browserResults += "Chrome: Installed"
        } else { $browserResults += "Chrome: Missing file"; $hasBrowserIssues = $true }
    } else { 
        $browserResults += "Browsers: Awaiting USB"
        $hasBrowserIssues = $true 
    }
    
    $bStatus = if ($hasBrowserIssues) { "WARN" } else { "ACTION" }
    Update-State 16 $bStatus ($browserResults -join " | ")

    Update-Current "Force installing Adobe AIR..."
    if (Ensure-InstallFiles) {
        $airExe = Get-ChildItem -Path $script:localInstalDir -Filter "AdobeAIR*.exe" | Select-Object -First 1
        if ($airExe) {
            Start-Process $airExe.FullName -ArgumentList "-silent" -Wait -NoNewWindow
            Update-State 18 "ACTION" "Installed unconditionally"
        } else { Update-State 18 "ERROR" "Installer missing" }
    } else { Update-State 18 "WARN" "Awaiting USB for AIR" }

    Update-Current "Force installing 7-Zip..."
    if (Ensure-InstallFiles) {
        $7zExe = Get-ChildItem -Path $script:localInstalDir -Filter "7z*.exe" | Select-Object -First 1
        if ($7zExe) {
            Start-Process $7zExe.FullName -ArgumentList "/S" -Wait -NoNewWindow
            Update-State 19 "ACTION" "Installed unconditionally"
        } else { Update-State 19 "ERROR" "Installer missing" }
    } else { Update-State 19 "WARN" "Awaiting USB for 7-Zip" }

    # ==========================
    # INSTALL ADOBE READER
    # ==========================
    Update-Current "Force installing Adobe Reader..."
    if (Ensure-InstallFiles) {
        $readerExe = Get-ChildItem -Path $script:localInstalDir -Filter "Reader_pl_install*.exe" | Select-Object -First 1
        if ($readerExe) {
            Start-Process $readerExe.FullName -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait -NoNewWindow
            Update-State 30 "ACTION" "Installed unconditionally"
        } else { Update-State 30 "ERROR" "Installer missing" }
    } else { Update-State 30 "WARN" "Awaiting USB for Reader" }

    # ==========================
    # COPY ARCABIT FOLDER TO DESKTOP
    # ==========================
    Update-Current "Copying Arcabit folder to Desktop..."
    if (Ensure-USB) {
        $usbArcabitPath = "$($script:usbDriveLetter):\ZSBrańsk\arcabit-ZSBransk"
        $localArcabitDir = "$env:USERPROFILE\Desktop\arcabit-ZSBransk"
        
        if (Test-Path $usbArcabitPath) {
            try {
                Copy-Item -Path $usbArcabitPath -Destination $localArcabitDir -Recurse -Force
                Update-State 32 "ACTION" "Copied to Desktop (Kept)"
            } catch {
                Update-State 32 "ERROR" $_.Exception.Message
            }
        } else {
            Update-State 32 "WARN" "Source folder not found"
        }
    } else {
        Update-State 32 "WARN" "USB Drive not found"
    }

    # ==========================
    # CLEANUP
    # ==========================
    Update-Current "Cleaning up temporary files..."
    if (Test-Path $script:localInstalDir) {
        # Usunie C:\Users\user\Desktop\INSTALKI
        # Zostawi C:\Users\user\Desktop\arcabit-ZSBransk
        Remove-Item -Path $script:localInstalDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Update-Current "Maintenance Complete."
    $sync.IsDone = $true
}

$btnStart.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtUnit.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Enter Target Unit.","Missing Data"); return
    }
    $btnStart.Enabled = $false
    $txtUnit.Enabled = $false
    $lblFooter.Text = "Running Maintenance..."

    $psRunspace = [runspacefactory]::CreateRunspace()
    $psRunspace.ApartmentState = "STA"
    $psRunspace.ThreadOptions = "ReuseThread"
    $psRunspace.Open()

    $powershell = [powershell]::Create()
    $powershell.Runspace = $psRunspace
    $powershell.AddScript($workerScriptBlock).AddArgument($syncHash).AddArgument($txtUnit.Text) | Out-Null
    $powershell.BeginInvoke() | Out-Null

    $script:activeRs = $psRunspace
    $script:activePs = $powershell
})

$uiTimer = New-Object System.Windows.Forms.Timer
$uiTimer.Interval = 400
$uiTimer.Add_Tick({
    $lblCurrent.Text = $syncHash.Current
    $progressBar.Value = [math]::Min($syncHash.Finished, $progressBar.Maximum)

    foreach ($gridRow in $dataGrid.Rows) {
        $itemId = [int]$gridRow.Cells["Id"].Value
        $itemStatus = $syncHash.Status[$itemId]
        $gridRow.Cells["Status"].Value = $itemStatus
        $gridRow.Cells["Detail"].Value = $syncHash.Detail[$itemId]
        
        $gridRow.DefaultCellStyle.BackColor = switch ($itemStatus) {
            "OK"      { [System.Drawing.Color]::LightGreen }
            "ACTION"  { [System.Drawing.Color]::Khaki }
            "ERROR"   { [System.Drawing.Color]::LightCoral }
            "WARN"    { [System.Drawing.Color]::LightSalmon }
            "SKIP"    { [System.Drawing.Color]::LightCyan }
            default   { [System.Drawing.Color]::White }
        }
    }

    if ($syncHash.IsDone) {
        $uiTimer.Stop()
        $lblFooter.Text = "Maintenance Completed."
        $btnStart.Text = "Done"
        [System.Windows.Forms.MessageBox]::Show("Maintenance finished. Check red/yellow highlights.","Completed")
    }
})
$uiTimer.Start()

$mainForm.Add_FormClosing({ $uiTimer.Stop() })
[void]$mainForm.ShowDialog()
