Get-ChildItem -Path . | Where-Object -Property Name -Like "*.packer.json" | ForEach-Object {
# Set Current Timestamp for packer build log
    $logtimestamp = (Get-Date -UFormat %Y%m%d%H%M%S)
    $build_output = "build_output_$logtimestamp.log"

    packer build $_.Name > $build_output

# Fetch osDiskUri from packer build
    $osDiskUri=(Get-Content $build_output | Select-String "OSDiskUri:") -Replace '.*https(.*\.vhd).*', 'https$1'

# Set osDiskUri as new image_uri in corresponding terraform file
    $terraformFile=($_.Name).Replace('.packer.json','.nontf')

    (Get-Content $terraformFile) -Replace 'image_uri.*', "image_uri = $([char]34)$osDiskUri$([char]34)" | Set-Content $terraformFile

    Write-Host "Replaced image_uri in $terraformFile with $osDiskUri"
}
