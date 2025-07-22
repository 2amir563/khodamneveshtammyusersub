#
# A comprehensive PowerShell script to manage user subscription configurations.
# Version 11.1: Fixed a critical regular expression typo in user-finding functions.
#

function Load-ExistingCodeBlock {
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Lotfan code `links = { ... }` ra az server ya file khod inja paste konid." -ForegroundColor Cyan
    Write-Host "Pas az paste kardan, dar yek khat jadid kalame 'END' ra type karde va Enter bezanid (ya 'cancel' baraye bazgasht)." -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    $pastedCode = ""
    while ($line = Read-Host) {
        if ($line.Trim().ToUpper() -eq 'END') { break }
        if ($line.Trim().ToLower() -in ('cancel', 'انصراف')) { return $null }
        $pastedCode += $line + "`r`n"
    }
    if (-not $pastedCode) { return $null }
    return $pastedCode.Trim()
}

function Add-NewUsers($existingCode) {
    if (-not $existingCode.Trim().EndsWith("}")) {
        Write-Host "Error: Code vared shode sakhtar sahihi nadarad." -ForegroundColor Red; return $existingCode
    }
    $userInput = Read-Host "Chand karbar JADID mikhahid ezafe konid? (baraye anseraf 'cancel' ra type konid)"
    if ($userInput.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
    try { $numUsers = [int]$userInput; if ($numUsers -le 0) { Write-Host "Adad mosbat." -ForegroundColor Yellow; return $existingCode } }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red; return $existingCode }
    $newUsersText = ""
    for ($i = 1; $i -le $numUsers; $i++) {
        Write-Host "`n--- Karbar Jadid #$i ---"
        $userName = Read-Host "Yek nam baraye in karbar vared konid (baraye anseraf 'cancel' ra type konid)"
        if ($userName.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
        $userUuid = [guid]::NewGuid().ToString()
        $userConfigs = New-Object System.Collections.ArrayList
        while ($true) {
            $numLinksInput = Read-Host "Be karbar '$userName' chand link mikhahid bedahid? (baraye anseraf 'cancel' ra type konid)"
            if ($numLinksInput.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
            try { $numLinks = [int]$numLinksInput; if ($numLinks -gt 0) { break } else { Write-Host "Adad bozorgtar az sefr." -ForegroundColor Yellow } }
            catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
        }
        for ($j = 1; $j -le $numLinks; $j++) { 
            $link = Read-Host "  Link #$j ra vared konid (baraye anseraf 'cancel' ra type konid)"
            if ($link.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
            [void]$userConfigs.Add($link) 
        }
        $newUsersText += "    # User: $userName`n"
        $newUsersText += "    '$userUuid': {`n"; $newUsersText += "        'DisplayName': '$userName',`n"; $newUsersText += "        'Configs': [`n"
        foreach ($config in $userConfigs) { $newUsersText += "            `"$config`",`n" }
        $newUsersText = $newUsersText.TrimEnd(",`n") + "`n        ]`n"; $newUsersText += "    },`n"
    }
    $lastBraceIndex = $existingCode.LastIndexOf("}")
    $finalCode = $existingCode.Insert($lastBraceIndex, $newUsersText)
    Write-Host "`n✅ Karbaran jadid ba moafaghiat be code ezafe shodand." -ForegroundColor Green
    return $finalCode
}

function Delete-User($existingCode) {
    if (-not $existingCode) { Write-Host "`nCode khali ast!" -ForegroundColor Yellow; return $existingCode }
    # *** Regex اصلاح شده ***
    $userMatches = $existingCode | Select-String -Pattern "(?m)^\s*# User:\s*(.+?)\s*`n\s*'([a-f0-9\-]+)'.*" -AllMatches
    if ($userMatches.Matches.Count -eq 0) { Write-Host "`nHich karbari baraye hazf peyda nashod." -ForegroundColor Yellow; return $existingCode }
    Write-Host "`n--- Entekhab Karbar baraye Hazf ---"
    for ($i = 0; $i -lt $userMatches.Matches.Count; $i++) {
        $displayName = $userMatches.Matches[$i].Groups[1].Value
        Write-Host "  $($i + 1). $displayName"
    }
    Write-Host "------------------------------------"
    $choice = Read-Host "Shomare karbari ke mikhahid hazf shavad ra vared konid (baraye anseraf 'cancel' ra type konid)"
    if ($choice.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
    try {
        $userIndex = [int]$choice - 1
        if ($userIndex -ge 0 -and $userIndex -lt $userMatches.Matches.Count) {
            $nameToDelete = $userMatches.Matches[$userIndex].Groups[1].Value
            $regexPattern = "(?ms)^\s*# User:\s*${nameToDelete}.*?^\s*\},?\s*`n"
            $modifiedCode = $existingCode -replace $regexPattern, ""
            Write-Host "`n✅ Karbar '$nameToDelete' ba moafaghiat hazf shod.`n" -ForegroundColor Green
            return $modifiedCode
        } else { Write-Host "Shomare na-motabar." -ForegroundColor Red; return $existingCode }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red; return $existingCode }
}

function Remove-LinkFromUser($existingCode) {
    if (-not $existingCode) { Write-Host "`nCode khali ast!" -ForegroundColor Yellow; return $existingCode }
    # *** Regex اصلاح شده ***
    $userMatches = $existingCode | Select-String -Pattern "(?ms)^\s*# User:\s*(.+?)\s*`n(.*?^\s*\},?\s*`n)" -AllMatches
    if ($userMatches.Matches.Count -eq 0) { Write-Host "`nHich karbari peyda nashod." -ForegroundColor Yellow; return $existingCode }
    Write-Host "`n--- Entekhab Karbar baraye Virayesh Link ---"
    for ($i = 0; $i -lt $userMatches.Matches.Count; $i++) {
        $displayName = $userMatches.Matches[$i].Groups[1].Value
        Write-Host "  $($i + 1). $displayName"
    }
    Write-Host "------------------------------------"
    $userChoice = Read-Host "Shomare karbari ke mikhahid link an ra hazf konid (baraye anseraf 'cancel' ra type konid)"
    if ($userChoice.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
    try {
        $userIndex = [int]$userChoice - 1
        if ($userIndex -ge 0 -and $userIndex -lt $userMatches.Matches.Count) {
            $userBlock = $userMatches.Matches[$userIndex].Groups[2].Value; $userName = $userMatches.Matches[$userIndex].Groups[1].Value
            $linkMatches = $userBlock | Select-String -Pattern '(?m)"(.*?)"' -AllMatches
            if ($linkMatches.Matches.Count -eq 0) { Write-Host "In karbar linki baraye hazf nadarad." -ForegroundColor Yellow; return $existingCode }
            Write-Host "`n--- Entekhab Link baraye Hazf (az karbar '$userName') ---"
            for ($j = 0; $j -lt $linkMatches.Matches.Count; $j++) {
                $linkDisplay = $linkMatches.Matches[$j].Groups[1].Value
                Write-Host "  $($j + 1). $linkDisplay"
            }
            Write-Host "------------------------------------"
            $linkChoice = Read-Host "Shomare linki ke mikhahid hazf shavad ra vared konid (baraye anseraf 'cancel' ra type konid)"
            if ($linkChoice.ToLower() -in ('cancel', 'انصراف')) { return $existingCode }
            $linkIndex = [int]$linkChoice - 1
            if ($linkIndex -ge 0 -and $linkIndex -lt $linkMatches.Matches.Count) {
                $linkToDelete = $linkMatches.Matches[$linkIndex].Groups[1].Value
                $lineToDeletePattern = "(?m)^\s*`"$([regex]::Escape($linkToDelete))`",?\s*`n"
                $modifiedUserBlock = $userBlock -replace $lineToDeletePattern, ""
                $modifiedCode = $existingCode.Replace($userBlock, $modifiedUserBlock)
                Write-Host "`n✅ Link entekhab shode ba moafaghiat hazf shod." -ForegroundColor Green
                return $modifiedCode
            } else { Write-Host "Shomare link na-motabar." -ForegroundColor Red; return $existingCode }
        } else { Write-Host "Shomare karbar na-motabar." -ForegroundColor Red; return $existingCode }
    }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red; return $existingCode }
}

function Generate-SubscriptionFile($codeBlock) {
    if (-not $codeBlock) { Write-Host "`nCode khali ast!" -ForegroundColor Yellow; return }
    Write-Host "`n--- Sakhtan File Link-ha ---"
    $serverIP = Read-Host "Adress IP ya Domian server khod ra vared konid"
    $serverPort = Read-Host "Port server khod ra vared konid"
    if (-not $serverIP -or -not $serverPort) { Write-Host "IP va Port nemitavanand khali bashand." -ForegroundColor Red; return }
    $scriptPath = $PSScriptRoot
    $filePath = Join-Path -Path $scriptPath -ChildPath "Subscription_Links.txt"
    $outputLines = @(); $outputLines += "--- Subscription Links ---"; $outputLines += "Generated on $(Get-Date)"; $outputLines += "--------------------------"
    # *** Regex اصلاح شده ***
    $userMatches = $codeBlock | Select-String -Pattern "(?m)^\s*# User:\s*(.+?)\s*`n\s*'([a-f0-9\-]+)'.*" -AllMatches
    foreach ($match in $userMatches.Matches) {
        $displayName = $match.Groups[1].Value; $uuid = $match.Groups[2].Value
        $url = "http://$serverIP`:$serverPort/$uuid"; $line = "${displayName}: $url"
        $outputLines += $line
    }
    $outputLines | Out-File -FilePath $filePath -Encoding utf8
    Write-Host "`n✅ File 'Subscription_Links.txt' ba moafaghiat dar pooshe اسکریپت sakhte shod." -ForegroundColor Green
}

function Print-FinalOutput($code) {
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "===        Khorooji Nahayi (Ready to Copy to Server)     ===" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    if (-not $code) { Write-Host "`nlinks = {}" } else { Write-Host "`n$code`n" }
    Write-Host "==========================================================" -ForegroundColor Green
}

function Save-ServerCodeToFile($codeBlock) {
    if (-not $codeBlock) { Write-Host "`nCode khali ast! Chizi baraye zakhire vojood nadarad." -ForegroundColor Yellow; return }
    $scriptPath = $PSScriptRoot
    $filePath = Join-Path -Path $scriptPath -ChildPath "server_code_for_upload.py"
    $codeBlock | Out-File -FilePath $filePath -Encoding utf8
    Write-Host "`n✅ Code nahayi server ba moafaghiat dar file 'server_code_for_upload.py' zakhire shod." -ForegroundColor Green
}


# --- منوی اصلی برنامه ---
$currentCodeBlock = ""
$exitLoop = $false
while (-not $exitLoop) {
    Write-Host "`n--- MENU ASLI ---"
    Write-Host "1. Sakhtan Yek List Jadid az Sefr"
    Write-Host "2. Virayesh List Mojood (Load kardan)"
    Write-Host "3. Namayesh Code Feli (baraye copy/paste dar server)"
    Write-Host "4. Zakhire Code Server dar File (.py)" -ForegroundColor Cyan
    Write-Host "5. Sakhtan File Nahayi Link-ha (.txt)" -ForegroundColor Yellow
    Write-Host "Q. Khorooj (Exit)"
    $menuChoice = Read-Host "Lotfan amaliat morede nazar ra entekhab konid"

    switch ($menuChoice.ToLower()) {
        '1' { 
            $currentCodeBlock = "links = {`n}"
            $result = Add-NewUsers $currentCodeBlock
            if ($result -ne $null) { $currentCodeBlock = $result; Print-FinalOutput $currentCodeBlock }
        }
        '2' { 
            $loadedCode = Load-ExistingCodeBlock
            if ($loadedCode -ne $null) {
                $currentCodeBlock = $loadedCode
                $editing = $true
                while ($editing) {
                    Write-Host "`n--- JALASE VIRAYESH --- (List Load Shode)"
                    Write-Host "E. Ezafe Kardan Karbar Jadid"
                    Write-Host "H. Hazf Kardan Karbar"
                    Write-Host "L. Hazf Kardan yek LINK khas az Karbar"
                    Write-Host "P. Chap Code Feli"
                    Write-Host "B. Bargasht be Menu Asli" -ForegroundColor Yellow
                    $subChoice = Read-Host "Amaliat Virayesh ra entekhab konid [E/H/L/P/B]"
                    
                    if (($subChoice.ToLower()) -in ('cancel', 'انصراف')) { continue }

                    $result = $null
                    switch ($subChoice.ToLower()) {
                        'e' { $result = Add-NewUsers $currentCodeBlock }
                        'h' { $result = Delete-User $currentCodeBlock }
                        'l' { $result = Remove-LinkFromUser $currentCodeBlock }
                        'p' { Print-FinalOutput $currentCodeBlock }
                        'b' { $editing = $false }
                        default { Write-Host "Entekhab na-motabar!" -ForegroundColor Red }
                    }
                    
                    if ($result -ne $null) {
                        $currentCodeBlock = $result
                        Print-FinalOutput $currentCodeBlock
                    }
                }
            }
        }
        '3' {
            Print-FinalOutput $currentCodeBlock
        }
        '4' {
            Save-ServerCodeToFile $currentCodeBlock
        }
        '5' {
            Generate-SubscriptionFile $currentCodeBlock
        }
        'q' { $exitLoop = $true }
        default { Write-Host "Entekhab na-motabar!" -ForegroundColor Red }
    }
}

Write-Host "`nProgram Payan Yaft."
Read-Host "Baraye baste shodan panjere yek kilid ra feshar dahid..."
