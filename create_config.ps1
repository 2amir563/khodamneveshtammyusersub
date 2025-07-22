#
# A comprehensive PowerShell script to manage user subscription configurations.
# Version 8.3: Fixed a variable parsing syntax error in the Generate-SubscriptionFile function.
#

function Load-ExistingCodeBlock {
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Lotfan code `links = { ... }` ra az server ya file khod inja paste konid." -ForegroundColor Cyan
    Write-Host "Pas az paste kardan, dar yek khat jadid kalame 'END' ra type karde va Enter bezanid." -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    $pastedCode = ""
    while ($line = Read-Host) {
        if ($line.Trim().ToUpper() -eq 'END') { break }
        $pastedCode += $line + "`r`n"
    }
    return $pastedCode.Trim()
}

function Add-NewUsers($existingCode) {
    if (-not $existingCode.Trim().EndsWith("}")) {
        Write-Host "Error: Code vared shode sakhtar sahihi nadarad (ba } payan nemiyabad)." -ForegroundColor Red
        return $existingCode
    }
    $userInput = Read-Host "Chand karbar JADID mikhahid ezafe konid?"
    try { $numUsers = [int]$userInput; if ($numUsers -le 0) { Write-Host "Adad mosbat." -ForegroundColor Yellow; return $existingCode } }
    catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red; return $existingCode }
    $newUsersText = ""
    for ($i = 1; $i -le $numUsers; $i++) {
        Write-Host "`n--- Karbar Jadid #$i ---"
        $userName = Read-Host "Yek nam baraye in karbar vared konid (masalan 'ali')"
        $userUuid = [guid]::NewGuid().ToString()
        $userConfigs = New-Object System.Collections.ArrayList
        while ($true) {
            try { $numLinks = [int](Read-Host "Be karbar '$userName' chand link mikhahid bedahid?"); if ($numLinks -gt 0) { break } else { Write-Host "Adad bozorgtar az sefr." -ForegroundColor Yellow } }
            catch { Write-Host "Voroodi na-motabar!" -ForegroundColor Red }
        }
        for ($j = 1; $j -le $numLinks; $j++) { $link = Read-Host "  Link #$j ra vared konid";[void]$userConfigs.Add($link) }
        
        $newUsersText += "    # User: $userName`n"
        $newUsersText += "    '$userUuid': {`n"
        $newUsersText += "        'DisplayName': '$userName',`n"
        $newUsersText += "        'Configs': [`n"
        foreach ($config in $userConfigs) {
            $newUsersText += "            `"$config`",`n"
        }
        $newUsersText = $newUsersText.TrimEnd(",`n") + "`n        ]`n"
        $newUsersText += "    },`n"
    }
    $lastBraceIndex = $existingCode.LastIndexOf("}")
    $finalCode = $existingCode.Insert($lastBraceIndex, $newUsersText)
    Write-Host "`n✅ Karbaran jadid ba moafaghiat be code ezafe shodand." -ForegroundColor Green
    return $finalCode
}

function Delete-User($existingCode) {
    if (-not $existingCode) { Write-Host "`nCode khali ast!" -ForegroundColor Yellow; return $existingCode }
    $userMatches = $existingCode | Select-String -Pattern "(?m)^\s*# User:\s*(.+?)\s*`n\s*'([a-f0-9\-]+)'.*" -AllMatches
    if ($userMatches.Matches.Count -eq 0) { Write-Host "`nHich karbari baraye hazf peyda nashod." -ForegroundColor Yellow; return $existingCode }
    Write-Host "`n--- Entekhab Karbar baraye Hazf ---"
    for ($i = 0; $i -lt $userMatches.Matches.Count; $i++) {
        $displayName = $userMatches.Matches[$i].Groups[1].Value
        Write-Host "  $($i + 1). $displayName"
    }
    Write-Host "------------------------------------"
    $choice = Read-Host "Shomare karbari ke mikhahid hazf shavad ra vared konid"
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

function Generate-SubscriptionFile($codeBlock) {
    if (-not $codeBlock) { Write-Host "`nCode khali ast! Hich linki baraye sakhtan vojood nadarad." -ForegroundColor Yellow; return }
    
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
    
    $userMatches = $codeBlock | Select-String -Pattern "(?m)^\s*# User:\s*(.+?)\s*`n\s*'([a-f0-9\-]+)'.*" -AllMatches

    foreach ($match in $userMatches.Matches) {
        $displayName = $match.Groups[1].Value
        $uuid = $match.Groups[2].Value
        $url = "http://$serverIP`:$serverPort/$uuid"
        
        # --- خط اصلاح شده اینجاست ---
        $line = "${displayName}: $url"
        
        $outputLines += $line
    }
    
    $outputLines | Out-File -FilePath $filePath -Encoding utf8
    
    Write-Host "`n✅ File 'Subscription_Links.txt' ba moafaghiat rooye Desktop shoma sakhte shod." -ForegroundColor Green
}

function Print-FinalOutput($code) {
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "===        Khorooji Nahayi (Ready to Copy to Server)     ===" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    if (-not $code) { Write-Host "`nlinks = {}" } else { Write-Host "`n$code`n" }
    Write-Host "==========================================================" -ForegroundColor Green
}

# --- منوی اصلی برنامه ---
$currentCodeBlock = ""
$exitLoop = $false
while (-not $exitLoop) {
    Write-Host "`n--- MENU ASLI ---"
    Write-Host "1. Sakhtan Yek List Jadid az Sefr"
    Write-Host "2. Virayesh List Mojood (Load kardan az code server)"
    Write-Host "3. Namayesh Code Nahayi (baraye copy/paste dar server)"
    Write-Host "4. Sakhtan File Nahayi Link-ha (.txt)" -ForegroundColor Yellow
    Write-Host "Q. Khorooj (Exit)"
    $menuChoice = Read-Host "Lotfan amaliat morede nazar ra entekhab konid"

    switch ($menuChoice.ToLower()) {
        '1' { 
            $currentCodeBlock = "links = {`n}"
            $currentCodeBlock = Add-NewUsers $currentCodeBlock
            Print-FinalOutput $currentCodeBlock
        }
        '2' { 
            $currentCodeBlock = Load-ExistingCodeBlock
            if ($currentCodeBlock) {
                $subChoice = Read-Host "Mikhahid Karbar (E)zafe ya (H)azf konid? [E/H]"
                if ($subChoice.ToLower() -eq 'e') {
                    $currentCodeBlock = Add-NewUsers $currentCodeBlock
                } elseif ($subChoice.ToLower() -eq 'h') {
                    $currentCodeBlock = Delete-User $currentCodeBlock
                }
                Print-FinalOutput $currentCodeBlock
            }
        }
        '3' {
            Print-FinalOutput $currentCodeBlock
        }
        '4' {
            Generate-SubscriptionFile $currentCodeBlock
        }
        'q' { $exitLoop = $true }
        default { Write-Host "Entekhab na-motabar!" -ForegroundColor Red }
    }
}

Write-Host "`nProgram Payan Yaft."
Read-Host "Baraye baste shodan panjere yek kilid ra feshar dahid..."
