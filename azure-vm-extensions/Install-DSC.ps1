New-Item -Path WSMan:\LocalHost\Listener -Transport HTTP -Address * -Force

New-Item -Path "C:\temp" -ItemType Directory

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name xActiveDirectory -Force

Invoke-WebRequest -Uri "https://storageaccount.blob.core.windows.net/azure-vm-extensions/DSC-Create-Domain.ps1" -OutFile "C:\temp\DSC-Create-Domain.ps1"

C:\temp\DSC-Create-Domain.ps1