<#
.SYNOPSIS
    Helper script, which does the actual Terraform call
.DESCRIPTION
    This script calls the actual terraform process for deployment and should only be called by Deploy-Pods, but not manually
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string]$TerraformAction,
    [Parameter(Mandatory=$true)]
    [string]$PodPath,
    [Parameter(Mandatory=$false)]
    [string]$TerraformOption
)

Set-Location $PodPath

terraform $TerraformAction $TerraformOption