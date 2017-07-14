$DomainName = "contoso.local"
$secpasswd = ConvertTo-SecureString "Password1234!" -AsPlainText -Force
$domainCred = New-Object System.Management.Automation.PSCredential ("contoso\pskurs", $secpasswd)
$safemodeAdministratorCred = New-Object System.Management.Automation.PSCredential ("contoso\pskurs", $secpasswd)

configuration NewDomain             
{             

param()             
            
Import-DscResource -ModuleName xActiveDirectory             
            
Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename               
    {             
            
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true         
        }            
            
      
                    
        WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }            
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }            
            
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {             
            DomainName = $DomainName             
            DomainAdministratorCredential = $domainCred             
            SafemodeAdministratorPassword = $safemodeAdministratorCred   
            DependsOn = "[WindowsFeature]ADDSInstall"           
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $domainCred
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        } 

        xADRecycleBin RecycleBin
        {
           EnterpriseAdministratorCredential = $domainCred
           ForestFQDN = $DomainName
           DependsOn = '[xWaitForADDomain]DscForestWait'
        }            

        ### OUs ###
        $DomainRoot = "DC=$($DomainName -replace '\.',',DC=')"
        $DependsOn_OU = @()

        ForEach ($RootOU in $ConfigurationData.NonNodeData.RootOUs) {

            xADOrganizationalUnit "OU_$RootOU"
            {
                Name = $RootOU
                Path = $DomainRoot
                ProtectedFromAccidentalDeletion = $true
                Description = "OU for $RootOU"
                Credential = $DomainCred
                Ensure = 'Present'
                DependsOn = '[xADRecycleBin]RecycleBin'
            }

            ForEach ($ChildOU in $ConfigurationData.NonNodeData.ChildOUs) {
                
                xADOrganizationalUnit "OU_$($RootOU)_$ChildOU"
                {
                    Name = $ChildOU
                    Path = "OU=$RootOU,$DomainRoot"
                    ProtectedFromAccidentalDeletion = $true
                    Credential = $DomainCred
                    Ensure = 'Present'
                    DependsOn = "[xADOrganizationalUnit]OU_$RootOU"
                }

                $DependsOn_OU += "[xADOrganizationalUnit]OU_$($RootOU)_$ChildOU"
            }

        }


        ### USERS ###
        $DependsOn_User = @()
        $Users = $ConfigurationData.NonNodeData.UserData | ConvertFrom-CSV
        ForEach ($User in $Users) {

            xADUser "NewADUser_$($User.UserName)"
            {
                DomainName = $DomainName
                Ensure = 'Present'
                UserName = $User.UserName
                JobTitle = $User.Title
                Path = "OU=Users,OU=$($User.Dept),$DomainRoot"
                Enabled = $true
                Password = New-Object -TypeName PSCredential -ArgumentList 'JustPassword', (ConvertTo-SecureString -String $User.Password -AsPlainText -Force)
                DependsOn = $DependsOn_OU
            }
            $DependsOn_User += "[xADUser]NewADUser_$($User.UserName)"
        }

        1..$ConfigurationData.NonNodeData.TestObjCount | ForEach-Object {

            xADUser "NewADUser_$_"
            {
                DomainName = $DomainName
                Ensure = 'Present'
                UserName = "TestUser$_"
                Enabled = $false  # Must specify $false if disabled and no password
                DependsOn = '[xADRecycleBin]RecycleBin'
            }

        }


        ### GROUPS ###
        ForEach ($RootOU in $ConfigurationData.NonNodeData.RootOUs) {
            xADGroup "NewADGroup_$RootOU"
            {
                GroupName = "G_$RootOU"
                GroupScope = 'Global'
                Description = "Global group for $RootOU"
                Category = 'Security'
                Members = ($Users | Where-Object {$_.Dept -eq $RootOU}).UserName
                Path = "OU=Groups,OU=$RootOU,$DomainRoot"
                Ensure = 'Present'
                DependsOn = $DependsOn_User
            }
        }

        1..$ConfigurationData.NonNodeData.TestObjCount | ForEach-Object {

            xADGroup "NewADGroup_$_"
            {
                GroupName = "TestGroup$_"
                GroupScope = 'Global'
                Category = 'Security'
                Members = "TestUser$_"
                Ensure = 'Present'
                DependsOn = "[xADUser]NewADUser_$_"
            }
        }
        
            
    }             
}       

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"  
            Role = "Primary DC"                  
            PsDscAllowPlainTextPassword = $true            
        }            
    )

    NonNodeData = @{

        UserData = @'
UserName,Password,Dept,Title
Alice,P@ssw0rd,Accounting,Manager
Bob,P@ssw0rd,IT,Manager
Charlie,P@ssw0rd,Marketing,Manager
Debbie,P@ssw0rd,Operations,Manager
Eddie,P@ssw0rd,Accounting,Specialist
Frieda,P@ssw0rd,IT,Specialist
George,P@ssw0rd,Marketing,Specialist
Harriet,P@ssw0rd,Operations,Specialist
'@

        RootOUs = 'Accounting','IT','Marketing','Operations'
        ChildOUs = 'Users','Computers','Groups'
        TestObjCount = 5

    }             
}                

# Run the configuration like a function
NewDomain -ConfigurationData $ConfigData

# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\NewDomain -Verbose 4> C:\temp\dsc_config_mgr.log
            
# Build the domain            
Start-DscConfiguration -Wait -Force -Path .\NewDomain -Verbose 4> C:\temp\dsc_configuration.log