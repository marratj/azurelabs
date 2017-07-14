Invoke-Command -ScriptBlock { 
    Get-WindowsFeature *domain* | Add-WindowsFeature –Restart 

    Import-Module ADDSDeployment

    Install-ADDSForest –DomainName "contoso.local" –InstallDNS:$true -Force -SafeModeAdministratorPassword (ConvertTo-SecureString –String "Password1234!" –AsPlainText -Force)
}