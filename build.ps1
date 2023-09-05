# Creates a .zip file and an azure policy

Import-Module az.resources

Set-Location $PSScriptRoot

connect-azaccount

if(Test-Path BechtleSchweizWindowsVirtualMachineConfiguration.zip){
    git rm BechtleSchweizWindowsVirtualMachineConfiguration.zip -f 
}

if(Test-Path policy){
    Remove-Item Policy -Recurse -Force
}

. .\vmdefaults.ps1

$params = @{
    Configuration = '.\vmdefaults\localhost.mof'
    Name = 'BechtleSchweizWindowsVirtualMachineConfiguration'
    Force = $true
    Type = 'AuditandSet'
}

$configuration = @{
    DisplayName = 'Bechtle Schweiz Default Windows Virtual Machine Congfiguration Policy'
    Description = 'Sets Default Regional Settings and installs SNMP Service'
    PolicyID = New-GUID
    PolicyVersion = '1.0.0'
    ContentUri = 'https://github.com/FiveH3ad/International_Reg/raw/main/BechtleSchweizWindowsVirtualMachineConfiguration.zip'
    Path = '.\policy'
    Platform = 'Windows'
    Mode = 'Applyandautocorrect'
}


New-GuestConfigurationPackage @params

Remove-Item .\vmdefaults -Recurse -Force

git add BechtleSchweizWindowsVirtualMachineConfiguration.zip
git commit -m 'default'
git push

Start-Sleep -Seconds 20

New-GuestConfigurationPolicy @Configuration

$policyfile = (Get-Childitem .\policy).fullname

New-AzPolicyDefinition -Name 'Bechtle Schweiz Default Windows Virtual Machine Congfiguration' -Policy $policyfile

git add *
git commit -m 'default'
git push