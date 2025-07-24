# update.ps1
function Build-Packages {
    # Tạo file JSON mới
    "[" | Out-File -FilePath "all.pkgs"
    
    # Kiểm tra thư mục debs
    if (-not (Test-Path "debs")) {
        Write-Error "Error: debs directory not found!"
        exit 1
    }
    
    # Lặp qua các file .deb
    Get-ChildItem "debs/*.deb" | ForEach-Object {
        $debInfo = dpkg -f $_.FullName
        
        # Xử lý thông tin
        $pkg = ($debInfo | Select-String "Package: ").ToString().Substring(9)
        $section = ($debInfo | Select-String "Section: ").ToString().Substring(9)
        $name = ($debInfo | Select-String "Name: ").ToString().Substring(6)
        $vers = ($debInfo | Select-String "Version: ").ToString().Substring(9)
        $author = ($debInfo | Select-String "Author: ").ToString().Substring(8)
        $depends = ($debInfo | Select-String "Depends: ").ToString().Substring(9)
        $description = ($debInfo | Select-String "Description: ").ToString().Substring(13)
        $arch = ($debInfo | Select-String "Architecture: ").ToString().Substring(14)
        
        $size = (Get-Item $_.FullName).Length
        $time = [int][double]::Parse((Get-Date -UFormat %s))
        
        # Tạo JSON entry
        $json = @{
            Name = $name
            Version = $vers
            Section = $section
            Package = $pkg
            Author = $author
            Depends = $depends
            Descript = $description
            Arch = $arch
            Size = $size
            Time = "${time}000"
        } | ConvertTo-Json -Compress
        
        Add-Content -Path "all.pkgs" -Value "$json,"
    }
    
    # Đóng file JSON
    "{}]" | Add-Content -Path "all.pkgs"
}

Write-Host "------------------"
Write-Host "Building Packages...."

# Tạo Packages
apt-ftparchive packages ./debs > ./Packages

# Tạo các phiên bản nén
bzip2 -c9k ./Packages > ./Packages.bz2
gzip -c9k ./Packages > ./Packages.gz

Write-Host "------------------"
Write-Host "Building Release...."

# Tính toán hash
$pkgMD5 = (Get-FileHash -Algorithm MD5 ./Packages).Hash
$pkgSize = (Get-Item ./Packages).Length
$pkgBz2MD5 = (Get-FileHash -Algorithm MD5 ./Packages.bz2).Hash
$pkgBz2Size = (Get-Item ./Packages.bz2).Length
$pkgGzMD5 = (Get-FileHash -Algorithm MD5 ./Packages.gz).Hash
$pkgGzSize = (Get-Item ./Packages.gz).Length

$pkgSHA256 = (Get-FileHash -Algorithm SHA256 ./Packages).Hash
$pkgBz2SHA256 = (Get-FileHash -Algorithm SHA256 ./Packages.bz2).Hash
$pkgGzSHA256 = (Get-FileHash -Algorithm SHA256 ./Packages.gz).Hash

# Tạo Release file
@"
Origin: Kho Lưu Trữ Romlayvn
Label: Kho Tinh Chỉnh iOS
Suite: stable
Version: 2.0
Codename: ios
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: Kho Tinh Chỉnh iOS Hiện Đại
MD5Sum:
 $pkgMD5 $pkgSize Packages
 $pkgBz2MD5 $pkgBz2Size Packages.bz2
 $pkgGzMD5 $pkgGzSize Packages.gz
SHA256:
 $pkgSHA256 $pkgSize Packages
 $pkgBz2SHA256 $pkgBz2Size Packages.bz2
 $pkgGzSHA256 $pkgGzSize Packages.gz
"@ | Out-File -FilePath Release -Encoding UTF8

Write-Host "------------------"
Write-Host "Done!"