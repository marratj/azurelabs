[System.Management.Automation.PSCredential]$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "contoso\pskurs", (ConvertTo-SecureString -String "Password1234!" -AsPlainText -Force)

Add-Computer -Credential $Credential -DomainName contoso.local -Restart