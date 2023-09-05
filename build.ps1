# Creates a .zip file and an azure policy

Import-Module az.resources

Set-Location $PSScriptRoot

connect-azaccount

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
    ContentUri = 'https://github.com/FiveH3ad/International_Reg/raw/main/BechtleSchweizVirtualMachineConfiguration.zip'
    Path = '.\policy'
    Platform = 'Windows'
    Mode = 'Applyandautocorrect'
}


New-GuestConfigurationPackage @params

New-GuestConfigurationPolicy @Configuration

$policyfile = (Get-Childitem .\policy).fullname

New-AzPolicyDefinition -Name 'Bechtle Schweiz Default Windows Virtual Machine Congfiguration' -Policy $policyfile

Remove-Item .\vmdefaults -Recurse -Force