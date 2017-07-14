<#
.SYNOPSIS
    Controls the Deployment of the Lab Pods
.DESCRIPTION
    This script controls the deployment of the defined lab pods by calling terraform in a separate window per Lab Pod
.EXAMPLE
    PS C:\> Deploy-Pods.ps1 -TerraformAction init
    Initializes the terraform state for each pod
.EXAMPLE
    PS C:\> Deploy-Pods.ps1 -TerraformAction plan
    Shows the terraform plan for each pod
.EXAMPLE
    PS C:\> Deploy-Pods.ps1 -TerraformAction apply
    Applys the terraform config for each pod
.EXAMPLE
    PS C:\> Deploy-Pods.ps1 -TerraformAction destroy -TerraformOption "-force"
    Destroys each pod bia terraform without further querying.
.INPUTS
    The Pod numbers and prefix are passed via environment variable from Clone-Template.ps1. 
    So before calling Deploy-Pods.ps1, make sure the Template Clone script has run again.
    
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TerraformAction,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$TerraformOption
)

 $PodBegin = $env:TF_PODBEGIN
 $PodEnd = $env:TF_PODEND
 $PodPrefix = $env:TF_PODPREFIX

 if ( -not $PodBegin ) {
     Write-Output "No TF_PODBEGIN count specified in environment"
     exit 1
 }
 elseif ( -not $PodEnd ) {
     Write-Output "No TF_PODEND count specified in environment"
     exit 1
 }
 elseif ( -not $PodPrefix ) {
     Write-Output "No TF_PODPREFIX count specified in environment"
     exit 1
 }

# Erstelle Anzahl an $podCount Kopien des Terraform Templates
# Rufe eigentlichen Terraform Prozess auf, welcher das Deployment uebernimmt
foreach($PodNumber in $PodBegin..$PodEnd) {
    Start-Process powershell '-NoExit', '-File .\Call-Terraform.ps1', "-PodPath .\$PodPrefix$PodNumber", "-TerraformAction $TerraformAction", "-TerraformOption $TerraformOption"
}