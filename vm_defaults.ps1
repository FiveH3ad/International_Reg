Configuration regionaldefaults {
    Import-DscResource -Name 'WindowsFeature' -ModuleName 'PSDesiredStateConfiguration'

    Import-DscResource -Name 'SystemLocale','TimeZone' -ModuleName 'ComputerManagementDsc'

    WindowsFeature 'SNMPFeature' {
        Name = 'SNMP-Service'
        Ensure = 'Present'
        IncludeAllSubFeature = true
        LogPath = 'C:\temp\snmpfeature.log'
    }
    
    SystemLocale 'SystemLocale' {
            IsSingleInstance = 'Yes'
            SystemLocale     = 'de-CH'
    }

    TimeZone 'TimeZone' {
            IsSingleInstance = 'Yes'
            TimeZone         = 'W. Europe Standard Time'
    }

    Script 'Culture' {
        GetScript = {@{ Result = Get-Culture}}
        SetScript = { 

            # Parameter
            $RegFileURL = "https://raw.githubusercontent.com/FiveH3ad/International_Reg/main/International.reg"
            $RegFile = "C:\Default_International.reg"

            # Download Registry File
            $webclient = New-Object System.Net.WebClient
            $webclient.DownloadFile($RegFileURL,$RegFile)

            $userprofiles = Get-Childitem C:\Users -Force -Exclude 'Default User','All Users','Public' -Directory | select name, fullname
            foreach($profile in $userprofiles){
                $username = $profile.name
                $profilepath = $profile.fullname
                if($username -ne 'Default'){
                    $usersid = Get-LocalUser $username | select sid 
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
                    
                    Set-ItemProperty -Path "$($UserRegPath)\Control Panel\International\🌎🌏🌍" -Name "Calendar" -Value "Gregorian"

                    & REG import $PersonalRegFile
                }
                else{
                    & REG LOAD HKU\Replace $NTuserDatPath

                    Remove-Item 'Registry::HKEY_USERS\Replace\Control Panel\International\User Profile' -Force -Recurse -confirm:$false -erroraction silentlycontinue
                    Remove-Item 'Registry::HKEY_USERS\Replace\Keyboard Layout\Preload' -Force -Recurse -confirm:$false -erroraction silentlycontinue

                    & REG Import $RegFile

                    $unloaded = $false
                    $attempts = 0
                    while (!$unloaded -and ($attempts -le 5)) {
                        [gc]::Collect() # necessary call to be able to unload registry hive
                        & REG UNLOAD HKU\Replace
                        $unloaded = $?
                        $attempts += 1
                    }
                }
            }
         }
        TestScript = { 'de-CH' -eq (Get-Culture).Name }
    }

}

regionaldefaults