#
# A comprehensive PowerShell script to manage user subscription configurations.
# Version 5.0: Added features to append links to existing users and generate a final links file.
#

function Load-ExistingLinks {
    $links = [ordered]@{ }
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Lotfan code ghabli khod (az `links = {` ta `}`) ra inja paste konid." -ForegroundColor Cyan
    Write-Host "Pas az paste kardan, dar yek khat jadid kalame 'END' ra type karde va Enter bezanid." -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    $pastedCode = ""
    while ($line = Read-Host) {
        if ($line.Trim().ToUpper() -eq 'END') { break }
        $pastedCode += $line + "`r`n"
    }
    try {
        $hashString = $pastedCode -replace '^\s*links\s*=\s*', ''
        $links = Invoke-Expression $hashString
        Write-Host "`n✅ List ghabli ba moafaghiat load shod.`n" -ForegroundColor Green
    } catch {
        Write-Host "`n❌ Error dar parse kardan code! Yek list khali sakhte mishavad.`n" -ForegroundColor Red
        $links = [ordered]@{ }
    }
    return $links
}

function Add-NewUsers($links) {
    $userInput = Read-Host "Chand karbar JADID mikhahid ezafe konid?"
    try {
        $numUsers = [int]$userInput
        if ($numUsers -le 0) { Write-Host "Adad mosbat vared konid." -ForegroundColor Yellow; return $links }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red; return $links }
    for ($i = 1; $i -le $numUsers; $i++) {
        Write-Host "`n--- Karbar Jadid #$i ---"
        $userName = Read-Host "Yek nam baraye in karbar vared konid (masalan 'ali')"
        $userUuid = [guid]::NewGuid().ToString()
        $userConfigs = New-Object System.Collections.ArrayList
        while ($true) {
            try {
                $numLinks = [int](Read-Host "Be karbar '$userName' chand link mikhahid bedahid?")
                if ($numLinks -gt 0) { break } else { Write-Host "Adad bozorgtar az sefr." -ForegroundColor Yellow }
            }
            catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
        }
        for ($j = 1; $j -le $numLinks; $j++) {
            $link = Read-Host "  Link #$j ra vared konid"
            [void]$userConfigs.Add($link)
        }
        $links[$userUuid] = @{ DisplayName = $userName; Configs = $userConfigs }
    }
    Write-Host "`n✅ Karbaran jadid ba moafaghiat ezafe shodand." -ForegroundColor Green
    return $links
}

function Delete-User($links) {
    if ($links.Count -eq 0) { Write-Host "`nList shoma khali ast!" -ForegroundColor Yellow; return $links }
    Write-Host "`n--- Entekhab Karbar baraye Hazf ---"
    $userList = @(); $links.GetEnumerator() | ForEach-Object { $userList += $_ }
    for ($i = 0; $i -lt $userList.Count; $i++) {
        Write-Host "  $($i + 1). $($userList[$i].Value.DisplayName) (ID: $($userList[$i].Name))"
    }
    Write-Host "------------------------------------"
    $choice = Read-Host "Shomare karbari ke mikhahid hazf shavad ra vared konid"
    try {
        $userIndex = [int]$choice - 1
        if ($userIndex -ge 0 -and $userIndex -lt $userList.Count) {
            $uuidToDelete = $userList[$userIndex].Name
            $nameToDelete = $userList[$userIndex].Value.DisplayName
            $links.Remove($uuidToDelete)
            Write-Host "`n✅ Karbar '$nameToDelete' ba moafaghiat hazf shod.`n" -ForegroundColor Green
        } else { Write-Host "Shomare vared shode na-motabar ast." -ForegroundColor Red }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
    return $links
}

function Add-LinksToUser($links) {
    # *** قابلیت جدید: افزودن لینک به کاربر موجود ***
    if ($links.Count -eq 0) { Write-Host "`nList shoma khali ast!" -ForegroundColor Yellow; return $links }
    Write-Host "`n--- Entekhab Karbar baraye Ezafe Kardan Link ---"
    $userList = @(); $links.GetEnumerator() | ForEach-Object { $userList += $_ }
    for ($i = 0; $i -lt $userList.Count; $i++) {
        Write-Host "  $($i + 1). $($userList[$i].Value.DisplayName) (Tedad Link Feli: $($userList[$i].Value.Configs.Count))"
    }
    Write-Host "------------------------------------"
    $choice = Read-Host "Be کدام karbar mikhahid link ezafe konid? (Shomare ra vared konid)"
    try {
        $userIndex = [int]$choice - 1
        if ($userIndex -ge 0 -and $userIndex -lt $userList.Count) {
            $uuidToModify = $userList[$userIndex].Name
            $nameToModify = $userList[$userIndex].Value.DisplayName
            $numLinksToAdd = [int](Read-Host "Chand link JADID mikhahid be '$nameToModify' ezafe konid?")
            for ($j = 1; $j -le $numLinksToAdd; $j++) {
                $newLink = Read-Host "  Link Jadid #$j ra vared konid"
                $links[$uuidToModify].Configs.Add($newLink)
            }
            Write-Host "`n✅ Link-haye jadid ba moafaghiat be '$nameToModify' ezafe shodand." -ForegroundColor Green
        } else { Write-Host "Shomare vared shode na-motabar ast." -ForegroundColor Red }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
    return $links
}

function Generate-SubscriptionFile($links) {
    # *** قابلیت جدید: ساخت فایل متنی از لینک‌ها ***
    if ($links.Count -eq 0) { Write-Host "`nList shoma khali ast! Hich linki baraye sakhtan vojood nadarad." -ForegroundColor Yellow; return }
    
    Write-Host "`n--- Sakhtan File Link-ha ---"
    $serverIP = Read-Host "Adress IP ya Domian server khod ra vared konid"
    $serverPort = Read-Host "Port server khod ra vared konid"
    
    if (-not $serverIP -or -not $serverPort) { Write-Host "IP va Port nemitavanand khali bashand." -ForegroundColor Red; return }

    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $filePath = Join-Path -Path $desktopPath -ChildPath "Subscription_Links.txt"
    
    $outputLines = @()
    $outputLines += "--- Subscription Links ---"
    $outputLines += "Generated on $(Get-Date)"
    $outputLines += "--------------------------"
    
    foreach ($entry in $links.GetEnumerator()) {
        $url = "http://$serverIP`:$serverPort/$($entry.Name)"
        $line = "$($entry.Value.DisplayName): $url"
        $outputLines += $line
    }
    
    $outputLines | Out-File -FilePath $filePath -Encoding utf8
    
    Write-Host "`n✅ File 'Subscription_Links.txt' ba moafaghiat rooye Desktop shoma sakhte shod." -ForegroundColor Green
}

function Print-FinalOutput($links) {
    # این تابع خروجی نهایی را با فرمت صحیح چاپ می‌کند
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "===        Khorooji Nahayi (Ready to Copy to Server)     ===" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    if ($links.Count -eq 0) { Write-Host "`nlinks = {}"; return }
    $outputString = "links = {`n"
    foreach ($entry in $links.GetEnumerator()) {
        $outputString += "    # User: $($entry.Value.DisplayName)`n"
        $outputString += "    '$($entry.Name)': [`n"
        foreach ($config in $entry.Value.Configs) {
            $outputString += "        `"$config`",`n"
        }
        $outputString = $outputString.TrimEnd(",`n") + "`n    ],`n"
    }
    $outputString = $outputString.TrimEnd(",`n") + "`n}"
    Write-Host "`n$outputString`n"
    Write-Host "==========================================================" -ForegroundColor Green
}


# --- منوی اصلی برنامه ---
$currentLinks = [ordered]@{ }
$exitLoop = $false

while (-not $exitLoop) {
    Write-Host "`n--- MENU ASLI ---"
    Write-Host "1. Sakhtan Yek List Jadid az Sefr"
    Write-Host "2. Ezafe Kardan Karbar Jadid be List Mojood"
    Write-Host "3. Ezafe Kardan LINK be Karbar Mojood"
    Write-Host "4. Hazf Kardan Karbar az List"
    Write-Host "5. Namayesh Code Nahayi (baraye copy kardan dar server)"
    Write-Host "6. Sakhtan File Nahayi Link-ha (.txt)"
    Write-Host "Q. Khorooj (Exit)"
    $menuChoice = Read-Host "Lotfan amaliat morede nazar ra entekhab konid"

    switch ($menuChoice.ToLower()) {
        '1' { $currentLinks = [ordered]@{}; $currentLinks = Add-NewUsers $currentLinks }
        '2' { if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }; $currentLinks = Add-NewUsers $currentLinks }
        '3' { if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }; $currentLinks = Add-LinksToUser $currentLinks }
        '4' { if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }; $currentLinks = Delete-User $currentLinks }
        '5' { Print-FinalOutput $currentLinks }
        '6' { if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }; Generate-SubscriptionFile $currentLinks }
        'q' { $exitLoop = $true }
        default { Write-Host "Entekhab na-motabar!" -ForegroundColor Red }
    }
}

Write-Host "`nProgram Payan Yaft."
Read-Host "Baraye baste shodan panjere yek kilid ra feshar dahid..."
