<#
    PRZEGLAD OKRESOWY KOMPUTERA - wersja z GUI
    Uruchamiane jednym poleceniem:
        irm https://raw.githubusercontent.com/Juliuszjk/sts-pc/refs/heads/main/Pc-update.ps1 | iex

    Pominiete celowo: 1, 2, 11, 15, 27, 28, 29, 30
    (11 - inna sprawa, robisz osobno; 15 - Office olewamy, wszedzie jest Libre)

    Bez pobierania z zewnatrz poza:
      - winget (juz zainstalowane programy -> aktualizacja, 7-Zip instalujemy jesli brak)
      - PSWindowsUpdate (PowerShell Gallery, do Windows Update)
      - Adobe AIR (Harman) instalator - z Twojego linku, TYLKO pobranie, bez instalacji
      - TeamViewerQS - z Twojego linku, tylko jesli nie ma go lokalnie
#>

$scriptUrl = "https://raw.githubusercontent.com/Juliuszjk/sts-pc/refs/heads/main/Pc-update.ps1"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm $scriptUrl | iex`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
# LISTA PUNKTOW (kolejnosc jak w checklisc papierowej)
# ============================================================
$items = @(
    @{ Nr=3;  Opis="Dane komputera (nazwa, system, konta)" }
    @{ Nr=4;  Opis="Aktualizacja systemu Windows" }
    @{ Nr=5;  Opis="Wylaczenie Smart App Control + Windows Defender" }
    @{ Nr=6;  Opis="HP Support Assistant (sterowniki)" }
    @{ Nr=7;  Opis="Rodzaj dysku" }
    @{ Nr=8;  Opis="Wolne miejsce na dysku" }
    @{ Nr=9;  Opis="Konto 'admin'" }
    @{ Nr=10; Opis="Konto 'adminb'" }
    @{ Nr=12; Opis="Pulpit zdalny dla wszystkich" }
    @{ Nr=13; Opis="Regula zapory - pulpit zdalny" }
    @{ Nr=14; Opis="LibreOffice" }
    @{ Nr=16; Opis="Firefox / Chrome" }
    @{ Nr=17; Opis="Adobe Reader" }
    @{ Nr=18; Opis="Pobranie Adobe AIR (Harman)" }
    @{ Nr=19; Opis="7-Zip" }
    @{ Nr=20; Opis="Java - wersja" }
    @{ Nr=21; Opis="Plik JAVA_PATH.txt" }
    @{ Nr=22; Opis="Bitdefender - otwarcie aplikacji" }
    @{ Nr=25; Opis="TeamViewer QS na pulpicie publicznym" }
    @{ Nr=26; Opis="BitLocker" }
)

# hashtable synchronizowana - most komunikacyjny miedzy watkiem roboczym a GUI
$sync = [hashtable]::Synchronized(@{
    Status  = @{}
    Detail  = @{}
    Current = "Oczekiwanie na start..."
    Done    = $false
    Total   = $items.Count
    Finished= 0
})
foreach ($it in $items) { $sync.Status[$it.Nr] = "OCZEKUJE"; $sync.Detail[$it.Nr] = "" }

# ============================================================
# POMOCNICZE FUNKCJE DO OTWIERANIA APLIKACJI
# ============================================================
function Open-WindowsDefender { Start-Process "windowsdefender:" }

function Find-StartMenuShortcut([string]$pattern) {
    $paths = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
               "$env:AppData\Microsoft\Windows\Start Menu\Programs")
    foreach ($p in $paths) {
        $f = Get-ChildItem -Path $p -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { return $f.FullName }
    }
    return $null
}

function Open-HPSupportAssistant {
    $candidates = @(
        "C:\Program Files (x86)\HP\HP Support Framework\HPSF.exe",
        "C:\Program Files\HP\HP Support Framework\HPSF.exe",
        "C:\Program Files (x86)\HP\HP Support Solutions Framework\HPSF.exe"
    )
    $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { $exe = Find-StartMenuShortcut "*HP Support Assistant*.lnk" }
    if ($exe) { Start-Process $exe; return $true }
    else { Start-Process "hpsupportassistant:" -ErrorAction SilentlyContinue; return $false }
}

function Open-Bitdefender {
    $candidates = @(
        "C:\Program Files\Bitdefender\Bitdefender Security Agent\bdagent.exe",
        "C:\Program Files\Bitdefender Endpoint Security Tools\bdagent.exe"
    )
    $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { $exe = Find-StartMenuShortcut "*Bitdefender*.lnk" }
    if ($exe) { Start-Process $exe; return $true }
    else { return $false }
}

# ============================================================
# BUDOWA OKNA GUI
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Przeglad okresowy komputera"
$form.Size = New-Object System.Drawing.Size(900,700)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lblJednostka = New-Object System.Windows.Forms.Label
$lblJednostka.Text = "Jednostka:"
$lblJednostka.Location = New-Object System.Drawing.Point(10,15)
$lblJednostka.AutoSize = $true
$form.Controls.Add($lblJednostka)

$txtJednostka = New-Object System.Windows.Forms.TextBox
$txtJednostka.Location = New-Object System.Drawing.Point(90,12)
$txtJednostka.Width = 200
$form.Controls.Add($txtJednostka)

$lblHaslo = New-Object System.Windows.Forms.Label
$lblHaslo.Text = "Haslo serwisowe (admin/adminb):"
$lblHaslo.Location = New-Object System.Drawing.Point(310,15)
$lblHaslo.AutoSize = $true
$form.Controls.Add($lblHaslo)

$txtHaslo = New-Object System.Windows.Forms.TextBox
$txtHaslo.Location = New-Object System.Drawing.Point(540,12)
$txtHaslo.Width = 150
$txtHaslo.UseSystemPasswordChar = $true
$form.Controls.Add($txtHaslo)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Rozpocznij przeglad"
$btnStart.Location = New-Object System.Drawing.Point(700,10)
$btnStart.Width = 170
$btnStart.Height = 30
$btnStart.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($btnStart)

$lblSzybkie = New-Object System.Windows.Forms.Label
$lblSzybkie.Text = "Szybkie otwieranie:"
$lblSzybkie.Location = New-Object System.Drawing.Point(10,50)
$lblSzybkie.AutoSize = $true
$form.Controls.Add($lblSzybkie)

$btnDefender = New-Object System.Windows.Forms.Button
$btnDefender.Text = "Windows Defender (5)"
$btnDefender.Location = New-Object System.Drawing.Point(140,45)
$btnDefender.Width = 160
$btnDefender.Add_Click({ Open-WindowsDefender })
$form.Controls.Add($btnDefender)

$btnHP = New-Object System.Windows.Forms.Button
$btnHP.Text = "HP Support Assistant (6)"
$btnHP.Location = New-Object System.Drawing.Point(310,45)
$btnHP.Width = 180
$btnHP.Add_Click({
    if (-not (Open-HPSupportAssistant)) {
        [System.Windows.Forms.MessageBox]::Show("Nie znaleziono HP Support Assistant na tym komputerze.","Info")
    }
})
$form.Controls.Add($btnHP)

$btnBD = New-Object System.Windows.Forms.Button
$btnBD.Text = "Bitdefender (22-24)"
$btnBD.Location = New-Object System.Drawing.Point(500,45)
$btnBD.Width = 160
$btnBD.Add_Click({
    if (-not (Open-Bitdefender)) {
        [System.Windows.Forms.MessageBox]::Show("Nie znaleziono Bitdefendera na tym komputerze.","Info")
    }
})
$form.Controls.Add($btnBD)

$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Text = "Oczekiwanie na start..."
$lblCurrent.Location = New-Object System.Drawing.Point(10,85)
$lblCurrent.AutoSize = $true
$lblCurrent.ForeColor = [System.Drawing.Color]::Blue
$lblCurrent.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblCurrent)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,110)
$progressBar.Width = 860
$progressBar.Height = 20
$progressBar.Maximum = $items.Count
$form.Controls.Add($progressBar)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10,140)
$grid.Size = New-Object System.Drawing.Size(860,480)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.RowHeadersVisible = $false
$grid.AutoSizeColumnsMode = "Fill"
$grid.SelectionMode = "FullRowSelect"
$grid.Columns.Add("Nr","Nr") | Out-Null
$grid.Columns.Add("Opis","Opis") | Out-Null
$grid.Columns.Add("Status","Status") | Out-Null
$grid.Columns.Add("Szczegoly","Szczegoly") | Out-Null
$grid.Columns["Nr"].FillWeight = 8
$grid.Columns["Opis"].FillWeight = 35
$grid.Columns["Status"].FillWeight = 15
$grid.Columns["Szczegoly"].FillWeight = 42

foreach ($it in $items) {
    $grid.Rows.Add($it.Nr, $it.Opis, "OCZEKUJE", "") | Out-Null
}
$form.Controls.Add($grid)

$grid.Add_CellDoubleClick({
    param($s,$e)
    if ($e.RowIndex -lt 0) { return }
    $nr = [int]$grid.Rows[$e.RowIndex].Cells["Nr"].Value
    switch ($nr) {
        5  { Open-WindowsDefender }
        6  { if (-not (Open-HPSupportAssistant)) { [System.Windows.Forms.MessageBox]::Show("Nie znaleziono HP Support Assistant.","Info") } }
        22 { if (-not (Open-Bitdefender)) { [System.Windows.Forms.MessageBox]::Show("Nie znaleziono Bitdefendera.","Info") } }
        default {
            $det = $grid.Rows[$e.RowIndex].Cells["Szczegoly"].Value
            [System.Windows.Forms.MessageBox]::Show($det, "Punkt $nr - szczegoly")
        }
    }
})

$lblStopka = New-Object System.Windows.Forms.Label
$lblStopka.Text = "Gotowy do startu."
$lblStopka.Location = New-Object System.Drawing.Point(10,630)
$lblStopka.AutoSize = $true
$form.Controls.Add($lblStopka)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Eksportuj raport CSV"
$btnExport.Location = New-Object System.Drawing.Point(700,625)
$btnExport.Width = 170
$btnExport.Add_Click({
    $path = "$env:USERPROFILE\Desktop\raport_przegladu_$env:COMPUTERNAME.csv"
    $rows = foreach ($r in $grid.Rows) {
        [pscustomobject]@{
            Nr=$r.Cells["Nr"].Value; Opis=$r.Cells["Opis"].Value
            Status=$r.Cells["Status"].Value; Szczegoly=$r.Cells["Szczegoly"].Value
        }
    }
    $rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Zapisano: $path","Eksport")
})
$form.Controls.Add($btnExport)

# ============================================================
# LOGIKA ROBOCZA (uruchamiana w osobnym runspace, zeby GUI nie zamarlo)
# ============================================================
$workerScript = {
    param($sync, $jednostka, $haslo)

    function Set-Status($nr, $status, $detail = "") {
        $sync.Status[$nr] = $status
        $sync.Detail[$nr] = $detail
        $sync.Finished++
    }
    function Set-Current($tekst) { $sync.Current = $tekst }

    $ErrorActionPreference = 'SilentlyContinue'
    $securePass = ConvertTo-SecureString $haslo -AsPlainText -Force

    Set-Current "Punkt 3 - dane komputera..."
    $nazwaKomputera = $env:COMPUTERNAME
    $os = Get-CimInstance Win32_OperatingSystem
    $adminsGroup = (Get-LocalGroupMember -Group "Administratorzy" -ErrorAction SilentlyContinue) `
                 + (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue)
    $adminNames = $adminsGroup.Name
    $ograniczeni = Get-LocalUser | Where-Object { $_.Enabled -and ($adminNames -notcontains "$nazwaKomputera\$($_.Name)") }
    Set-Status 3 "OK" "Nazwa: $nazwaKomputera | $($os.Caption) | Jednostka: $jednostka | Konta ograniczone: $(($ograniczeni.Name) -join ', ')"

    Set-Current "Punkt 5 - Smart App Control + Windows Defender..."
    try {
        $sacPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        $sacInfo = "brak klucza"
        if (Test-Path $sacPath) {
            $val = (Get-ItemProperty -Path $sacPath -Name VerifiedAndReputablePolicyState -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
            if ($val -ne 0) {
                New-ItemProperty -Path $sacPath -Name VerifiedAndReputablePolicyState -PropertyType DWord -Value 0 -Force | Out-Null
                $sacInfo = "wylaczono (moze wymagac restartu)"
            } else { $sacInfo = "juz wylaczona" }
        }
        Start-Process "windowsdefender:"
        Set-Status 5 "OK" "SAC: $sacInfo | Windows Defender otwarty"
    } catch { Set-Status 5 "BRAK" $_.Exception.Message }

    Set-Current "Punkt 6 - otwieranie HP Support Assistant..."
    $hpCandidates = @(
        "C:\Program Files (x86)\HP\HP Support Framework\HPSF.exe",
        "C:\Program Files\HP\HP Support Framework\HPSF.exe",
        "C:\Program Files (x86)\HP\HP Support Solutions Framework\HPSF.exe"
    )
    $hpExe = $hpCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($hpExe) { Start-Process $hpExe; Set-Status 6 "OK" "otwarto HP Support Assistant" }
    else { Set-Status 6 "BRAK" "nie znaleziono HP Support Assistant - sprawdz recznie" }

    Set-Current "Punkt 7 - rodzaj dysku..."
    $dyski = Get-PhysicalDisk | Select-Object DeviceId, MediaType
    Set-Status 7 "OK" (($dyski.MediaType | Sort-Object -Unique) -join "+")

    Set-Current "Punkt 8 - wolne miejsce na dysku..."
    $vol = Get-Volume -DriveLetter C
    $procent = [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 1)
    $kat = if ($procent -gt 50) { "wiecej niz 50%" } elseif ($procent -ge 25) { "50%-25%" } elseif ($procent -ge 10) { "25%-10%" } else { "PONIZEJ 10% - INTERWENCJA" }
    Set-Status 8 $(if ($procent -lt 10) { "BRAK" } else { "OK" }) "$procent% ($kat)"

    foreach ($konto in @("admin","adminb")) {
        $numer = if ($konto -eq 'admin') { 9 } else { 10 }
        Set-Current "Punkt $numer - konto '$konto'..."
        $u = Get-LocalUser -Name $konto -ErrorAction SilentlyContinue
        if ($u) {
            Set-LocalUser -Name $konto -Password $securePass -ErrorAction SilentlyContinue
            if (-not $u.Enabled) { Enable-LocalUser -Name $konto }
            Set-Status $numer "OK" "istnieje, haslo zaktualizowane"
        } else {
            New-LocalUser -Name $konto -Password $securePass -PasswordNeverExpires -AccountNeverExpires | Out-Null
            Add-LocalGroupMember -Group "Administratorzy" -Member $konto -ErrorAction SilentlyContinue
            Add-LocalGroupMember -Group "Administrators" -Member $konto -ErrorAction SilentlyContinue
            Set-Status $numer "AKCJA" "utworzono i dodano do administratorow"
        }
    }

    Set-Current "Punkt 12/13 - pulpit zdalny..."
    try {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Pulpit zdalny" -ErrorAction SilentlyContinue
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Uzytkownicy pulpitu zdalnego" -Member "Uzytkownicy" -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Users" -ErrorAction SilentlyContinue
        Set-Status 12 "OK" "wlaczono, grupa Uzytkownicy dodana"
        Set-Status 13 "OK" "reguly zapory wlaczone"
    } catch {
        Set-Status 12 "BRAK" $_.Exception.Message
        Set-Status 13 "BRAK" $_.Exception.Message
    }

    Set-Current "Punkt 14 - LibreOffice..."
    $loKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $libreOffice = Get-ItemProperty $loKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "LibreOffice*" }
    if ($libreOffice) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade --id TheDocumentFoundation.LibreOffice -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        }
        Set-Status 14 "OK" "wykryto ($($libreOffice.DisplayVersion)), wyslano aktualizacje"
    } else {
        Set-Status 14 "INFO" "nie znaleziono - pomijam (nie instalujemy)"
    }

    Set-Current "Punkt 16 - Firefox / Chrome..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wynik16 = @()
        foreach ($app in @(@{id="Mozilla.Firefox";n="Firefox"}, @{id="Google.Chrome";n="Chrome"})) {
            $zainstalowany = winget list --id $app.id -e 2>$null | Select-String $app.id
            if ($zainstalowany) {
                winget upgrade --id $app.id -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
                $wynik16 += "$($app.n): aktualizacja wyslana"
            } else { $wynik16 += "$($app.n): niezainstalowany" }
        }
        Set-Status 16 "OK" ($wynik16 -join " | ")
    } else { Set-Status 16 "BRAK" "winget niedostepny" }

    Set-Current "Punkt 17 - Adobe Reader..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $ar = winget list --id Adobe.Acrobat.Reader.64-bit -e 2>$null | Select-String "Adobe.Acrobat.Reader"
        if ($ar) {
            winget upgrade --id Adobe.Acrobat.Reader.64-bit -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
            Set-Status 17 "OK" "aktualizacja wyslana"
        } else { Set-Status 17 "INFO" "niezainstalowany - pomijam" }
    }

    Set-Current "Punkt 18 - pobieranie Adobe AIR..."
    try {
        $dest = "$env:USERPROFILE\Desktop\AdobeAIR_Installer.exe"
        Invoke-WebRequest -Uri "https://airsdk.harman.com/assets/downloads/51.3.3.1/AdobeAIR.exe" -OutFile $dest -UseBasicParsing
        Set-Status 18 "AKCJA" "pobrano na pulpit: $dest - zainstaluj recznie"
    } catch { Set-Status 18 "BRAK" $_.Exception.Message }

    Set-Current "Punkt 19 - 7-Zip..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $sevenzip = winget list --id 7zip.7zip -e 2>$null | Select-String "7zip.7zip"
        if ($sevenzip) {
            winget upgrade --id 7zip.7zip -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
            Set-Status 19 "OK" "juz zainstalowany, aktualizacja wyslana"
        } else {
            winget install --id 7zip.7zip -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
            Set-Status 19 "AKCJA" "zainstalowano"
        }
    }

    Set-Current "Punkt 20/21 - Java..."
    $javaVer = & java -version 2>&1
    if ($javaVer -match "version") {
        Set-Status 20 "OK" (($javaVer | Select-Object -First 1) -join " ")
    } else { Set-Status 20 "BRAK" "brak java w PATH" }

    $javaPathFile = Get-ChildItem -Path "C:\","$env:PUBLIC\Desktop","$env:USERPROFILE\Desktop" -Filter "JAVA_PATH.txt" -ErrorAction SilentlyContinue
    if ($javaPathFile) { Set-Status 21 "OK" "znaleziono: $($javaPathFile.FullName)" }
    else { Set-Status 21 "BRAK" "nie znaleziono - utworz recznie" }

    Set-Current "Punkt 22-24 - otwieranie Bitdefendera..."
    $bdCandidates = @(
        "C:\Program Files\Bitdefender\Bitdefender Security Agent\bdagent.exe",
        "C:\Program Files\Bitdefender Endpoint Security Tools\bdagent.exe"
    )
    $bdExe = $bdCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($bdExe) { Start-Process $bdExe; Set-Status 22 "OK" "otwarto Bitdefendera - kliknij aktualizuj recznie" }
    else { Set-Status 22 "BRAK" "nie znaleziono Bitdefendera - sprawdz recznie" }

    Set-Current "Punkt 25 - TeamViewer QS..."
    $publicDesktop = "$env:PUBLIC\Desktop"
    $userDesktop = "$env:USERPROFILE\Desktop"
    $naPublicznym = Get-ChildItem $publicDesktop -Filter "TeamViewerQS*.exe" -ErrorAction SilentlyContinue
    if ($naPublicznym) {
        if ($naPublicznym.Count -gt 1) {
            $naPublicznym | Sort-Object LastWriteTime -Descending | Select-Object -Skip 1 | Remove-Item -Force
        }
        Set-Status 25 "OK" "juz obecny na pulpicie publicznym"
    } else {
        $naUserze = Get-ChildItem $userDesktop -Filter "TeamViewerQS*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($naUserze) {
            Move-Item $naUserze.FullName -Destination $publicDesktop -Force
            Set-Status 25 "AKCJA" "przeniesiono z pulpitu uzytkownika"
        } else {
            try {
                $dest = Join-Path $publicDesktop "TeamViewerQS.exe"
                Invoke-WebRequest -Uri "https://get.teamviewer.com/6kqdjfd" -OutFile $dest -UseBasicParsing
                Set-Status 25 "AKCJA" "pobrano na pulpit publiczny"
            } catch { Set-Status 25 "BRAK" $_.Exception.Message }
        }
    }

    Set-Current "Punkt 26 - BitLocker..."
    $bl = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    if ($bl) {
        if ($bl.ProtectionStatus -eq 'On') { Set-Status 26 "OK" "ochrona wlaczona, status: $($bl.VolumeStatus)" }
        else { Set-Status 26 "BRAK" "ochrona wylaczona lub nieskonfigurowana" }
    } else { Set-Status 26 "BRAK" "BitLocker niedostepny" }

    Set-Current "Punkt 4 - aktualizacja Windows (moze potrwac dlugo)..."
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-PackageProvider -Name NuGet -Force | Out-Null
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers
        }
        Import-Module PSWindowsUpdate
        try {
            $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
            $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") | Out-Null
        } catch {}
        Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot | Out-Null
        Set-Status 4 "OK" "zainstalowano dostepne aktualizacje - sprawdz czy wymagany restart"
    } catch { Set-Status 4 "BRAK" $_.Exception.Message }

    Set-Current "Zakonczono przeglad."
    $sync.Done = $true
}

$btnStart.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtJednostka.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Podaj jednostke.","Brak danych"); return
    }
    if ([string]::IsNullOrWhiteSpace($txtHaslo.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Podaj haslo serwisowe.","Brak danych"); return
    }
    $btnStart.Enabled = $false
    $txtJednostka.Enabled = $false
    $txtHaslo.Enabled = $false
    $lblStopka.Text = "Trwa przeglad..."

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    $ps.AddScript($workerScript).AddArgument($sync).AddArgument($txtJednostka.Text).AddArgument($txtHaslo.Text) | Out-Null
    $ps.BeginInvoke() | Out-Null

    $script:activeRunspace = $runspace
    $script:activePs = $ps
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 400
$timer.Add_Tick({
    $lblCurrent.Text = $sync.Current
    $progressBar.Value = [math]::Min($sync.Finished, $progressBar.Maximum)

    foreach ($row in $grid.Rows) {
        $nr = [int]$row.Cells["Nr"].Value
        $status = $sync.Status[$nr]
        $row.Cells["Status"].Value = $status
        $row.Cells["Szczegoly"].Value = $sync.Detail[$nr]
        $row.DefaultCellStyle.BackColor = switch ($status) {
            "OK"      { [System.Drawing.Color]::LightGreen }
            "AKCJA"   { [System.Drawing.Color]::Khaki }
            "BRAK"    { [System.Drawing.Color]::LightCoral }
            "INFO"    { [System.Drawing.Color]::LightCyan }
            default   { [System.Drawing.Color]::White }
        }
    }

    if ($sync.Done) {
        $timer.Stop()
        $lblStopka.Text = "Przeglad zakonczony."
        $btnStart.Text = "Zakonczono"
        [System.Windows.Forms.MessageBox]::Show("Przeglad zakonczony. Sprawdz punkty oznaczone na czerwono/zolto.","Gotowe")
    }
})
$timer.Start()

$form.Add_FormClosing({ $timer.Stop() })
[void]$form.ShowDialog()
