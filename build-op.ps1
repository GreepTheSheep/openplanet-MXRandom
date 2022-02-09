$compress = @{
    Path = "./info.toml", "./src"
    CompressionLevel = "Fastest"
    DestinationPath = "./MXRandom.zip"
}
Compress-Archive @compress -Force

Move-Item -Path "./MXRandom.zip" -Destination "./MXRandom.op" -Force

Write-Host("Done!")