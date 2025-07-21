#
# A comprehensive PowerShell script to manage user subscription configurations.
# Version 4.0: Definitive fix for the main exit loop logic.
#

function Load-ExistingLinks {
    # این تابع کد قبلی را از کاربر دریافت کرده و به آبجکت پاورشل تبدیل می‌کند
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
    # این تابع کاربران جدید را به لیست موجود اضافه می‌کند
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
        $links[$userUuid] = @{
            DisplayName = $userName
            Configs = $userConfigs
        }
    }
    Write-Host "`n✅ Karbaran jadid ba moafaghiat ezafe shodand." -ForegroundColor Green
    return $links
}

function Delete-User($links) {
    # این تابع یک کاربر را از لیست حذف می‌کند
    if ($links.Count -eq 0) {
        Write-Host "`nList shoma khali ast! Hich karbari baraye hazf vojood nadarad." -ForegroundColor Yellow
        return $links
    }

    Write-Host "`n--- Entekhab Karbar baraye Hazf ---"
    $userList = @()
    $links.GetEnumerator() | ForEach-Object { $userList += $_ }
    
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
        } else {
            Write-Host "Shomare vared shode na-motabar ast." -ForegroundColor Red
        }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
    
    return $links
}

function Print-FinalOutput($links) {
    # این تابع خروجی نهایی را با فرمت صحیح چاپ می‌کند
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "===        Khorooji Nahayi va TARKIBI (Ready to Copy)      ===" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green

    if ($links.Count -eq 0) {
        Write-Host "`nlinks = {}"
        return
    }

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
$exitLoop = $false # <--- تغییر ۱: تعریف یک پرچم برای کنترل حلقه

while (-not $exitLoop) { # <--- تغییر ۲: حلقه تا زمانی که پرچم نادرست است ادامه دارد
    Write-Host "`n--- MENU ASLI ---"
    Write-Host "1. Ezafe Kardan Karbar be List"
    Write-Host "2. Hazf Kardan Karbar az List"
    Write-Host "3. Sakhtan Yek List Jadid az Sefr"
    Write-Host "4. Namayesh List Feli"
    Write-Host "Q. Khorooj (Exit)"
    $menuChoice = Read-Host "Lotfan amaliat morede nazar ra entekhab konid"

    switch ($menuChoice.ToLower()) {
        '1' { 
            if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }
            $currentLinks = Add-NewUsers $currentLinks 
        }
        '2' { 
            if ($currentLinks.Count -eq 0) { $currentLinks = Load-ExistingLinks }
            $currentLinks = Delete-User $currentLinks 
        }
        '3' { 
            $currentLinks = [ordered]@{}; 
            $currentLinks = Add-NewUsers $currentLinks 
        }
        '4' {
            Print-FinalOutput $currentLinks
        }
        'q' { 
            $exitLoop = $true # <--- تغییر ۳: به جای break، مقدار پرچم را برای خروج تغییر می‌دهیم
        }
        default { Write-Host "Entekhab na-motabar!" -ForegroundColor Red }
    }
}

Write-Host "`nProgram Payan Yaft."
Read-Host "Baraye baste shodan panjere yek kilid ra feshar dahid..."
