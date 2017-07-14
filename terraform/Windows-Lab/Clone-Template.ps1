<#
.SYNOPSIS
    Clones terraform environments from a template folder
.DESCRIPTION
    This script clones the template folder into the specified number of lab pods.
    It passes the number of pods into environment variables, which then can be used by Deploy-Pods.ps1
.EXAMPLE
    PS C:\> Clone-Templates.ps1 -PodBegin 1 -PodEnd 5
    Clones the template folder into the directories pod1 to pod5 and replaces the template name in the terraform configs with the pod number.
.EXAMPLE
    PS C:\> Clone-Templates.ps1 -PodBegin 1 -PodEnd 5 -Region "northeurope"
    Same as above, but switches the Azure deployment region from the default westeurope to northeurope.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Default CPU core limit per Azure region is 20. Keep that in mind when cloning the template into pods
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [Alias('Begin')]
    [ValidateRange(1,10)]
    [int]$PodBegin = 1,
    
    [Parameter(Mandatory=$true)]
    [Alias('End')]
    [ValidateRange(1,10)]
    [int]$PodEnd = 6,

    [ValidateSet("westeurope", "northeurope")]
    $Region = "westeurope",

    $PodPrefix = "pod"
)

# Setze die Parameter in Environment-Variablen zur Weitervendung durch den Terraform-Call
$env:TF_PODBEGIN = $PodBegin
$env:TF_PODEND = $PodEnd
$env:TF_PODPREFIX = $PodPrefix

# Erstelle Anzahl an $podCount Kopien des Terraform Templates
foreach($PodNumber in $PodBegin..$PodEnd) {
    Copy-Item -Path .\template -Destination "$PodPrefix$PodNumber" -Recurse -Exclude "terraform.tfstate"
    
    $Files = Get-ChildItem -Path "$PodPrefix$PodNumber" | Where-Object -Property Name -Like "*.tf"

    # Ersetze template-Namen durch $PodPrefix in den .tf Configs
    # Ersetze ausserdem Region westeurope durch angegebene $Region
    foreach ($File in $Files) {
        $Filepath = Join-Path -Path "$PodPrefix$PodNumber" -ChildPath $File
        $podreplaced = (Get-Content $Filepath).Replace("template", "pod$PodNumber") 
        $regionreplaced = $podreplaced.Replace("westeurope", "$Region")
        $regionreplaced | Set-Content -Path $Filepath
    }
}


