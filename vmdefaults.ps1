Configuration vmdefaults {
    Import-DscResource -Name 'WindowsFeature','Script' -ModuleName 'PSDscResources'

    WindowsFeature 'SNMPFeature' {
        Name = 'SNMP-Service'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
        LogPath = 'C:\temp\snmpfeature.log'
    }
    Script 'Computer_Locale'{
        GetScript = {@{Result = (Get-WinSystemLocale).name}}
        SetScript = { Set-WinSystemLocale -SystemLocale 'de-CH' }
        TestScript = { 'de-CH' -eq (Get-WinSystemLocale).name}
    }
    
    Script 'Computer_TimeZone'{
        GetScript = {@{ Result = (Get-TimeZone).ID}}
        SetScript = { Set-TimeZone -Id 'W. Europe Standard Time' }
        TestScript = { 'W. Europe Standard Time' -eq (Get-TimeZone).ID }
    }
    
    Script 'Culture' {
        GetScript = {
            $RegFilePath = 'C:\Users\Default\NTUSER.DAT'
            $RegLoadPath = 'HKLM\Default'

            & REG LOAD $RegLoadPath $RegFilePath > $null 2>&1

            $LocaleValue = Get-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\Default\Control Panel\International' -Name 'LocaleName'

            $unloaded = $false
            $attempts = 0
            while (!$unloaded -and ($attempts -le 5)) {
                [gc]::Collect() # necessary call to be able to unload registry hive
                & REG UNLOAD HKU\Replace > $null 2>&1
                $unloaded = $?
                $attempts += 1
            }
            @{ Result = $LocaleValue }
        } 
        SetScript = {
            # Parameter
            $RegFileURL = "https://raw.githubusercontent.com/FiveH3ad/International_Reg/main/International.reg"
            $RegFile = "C:\Default_International.reg"

            # Download Registry File
            $webclient = New-Object System.Net.WebClient
            $webclient.DownloadFile($RegFileURL,$RegFile)

            $userprofiles = Get-Childitem C:\Users -Force -Exclude 'Default User','All Users','Public' -Directory | Select-Object name, fullname
            foreach($profile in $userprofiles){
                $username = $profile.name
                $profilepath = $profile.fullname
                if($username -ne 'Default'){
                    $usersid = Get-LocalUser $username | Select-Object sid 
                    $usersid = $usersid.SID.Value
                }
                else{
                    $usersid = "None"
                }
                
                $UserRegPath = "Registry::HKEY_USERS\$($usersid)"
                
                $NTuserDatPath = Join-Path $profilepath "NTUSER.DAT"

                # Check if Hive is loaded or not
                if(Test-Path $UserRegPath){
                    $PersonalRegFile = (Split-Path $RegFile -Parent) + "$username" + '.reg'
                    $RegFileContent = Get-Content $RegFile
                    $PersonalRegFileContent = $RegFileContent -Replace 'HKEY_USERS\\Replace',"HKEY_USERS\$usersid"
                    Set-Content -Path $PersonalRegFile -Value $PersonalRegFileContent

                    Remove-Item "$($UserRegPath)\Control Panel\International\User Profile" -Force -Recurse -confirm:$false -erroraction silentlycontinue
                    Remove-Item "$($UserRegPath)\Keyboard Layout\Preload" -Force -Recurse -confirm:$false -erroraction silentlycontinue

                    & REG import $PersonalRegFile > $null 2>&1
                }
                else{
                    & REG LOAD HKU\Replace $NTuserDatPath > $null 2>&1

                    Remove-Item 'Registry::HKEY_USERS\Replace\Control Panel\International\User Profile' -Force -Recurse -confirm:$false -erroraction silentlycontinue
                    Remove-Item 'Registry::HKEY_USERS\Replace\Keyboard Layout\Preload' -Force -Recurse -confirm:$false -erroraction silentlycontinue

                    & REG Import $RegFile > $null 2>&1

                    $unloaded = $false
                    $attempts = 0
                    while (!$unloaded -and ($attempts -le 5)) {
                        [gc]::Collect() # necessary call to be able to unload registry hive
                        & REG UNLOAD HKU\Replace > $null 2>&1
                        $unloaded = $?
                        $attempts += 1
                    }
                }
            }
        }
        TestScript = { 
            $RegFilePath = 'C:\Users\Default\NTUSER.DAT'
            $RegLoadPath = 'HKLM\Default'

            & REG LOAD $RegLoadPath $RegFilePath > $null 2>&1

            $LocaleValue = Get-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\Default\Control Panel\International' -Name 'LocaleName'

            $unloaded = $false
            $attempts = 0
            while (!$unloaded -and ($attempts -le 5)) {
                [gc]::Collect() # necessary call to be able to unload registry hive
                & REG UNLOAD HKU\Replace > $null 2>&1
                $unloaded = $?
                $attempts += 1
            }
            'de-CH' -eq $LocaleValue.LocaleName
        }
    }
}

vmdefaults