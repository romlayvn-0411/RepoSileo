#!/bin/sh

function building() {
  echo "[" > all.pkgs
  
  # Kiểm tra thư mục debs/
  if [ ! -d "debs" ]; then
    echo "Error: debs directory not found!"
    exit 1
  fi

  if [[ -e compatity.txt ]]; then
    compatity=$(cat compatity.txt)
  fi

  # Kiểm tra có file .deb nào không
  if [ ! "$(ls -A debs/*.deb 2>/dev/null)" ]; then
    echo "Error: No .deb files found in debs directory!"
    exit 1
  fi

  for i in debs/*.deb
  do
    if [ ! -f "$i" ]; then
      continue
    fi
    
    debInfo=`dpkg -f $i`
    if [ $? -ne 0 ]; then
      echo "Error reading $i"
      continue
    fi
    
    pkg=`echo "$debInfo" | grep "Package: " | cut -c 10- | tr -d "\n\r"`

   section=`echo "$debInfo" | grep "Section: " | cut -c 10- | tr -d "\n\r"`
   section="${section//'"'/\\\"}"

   name=`echo "$debInfo" | grep "Name: " | cut -c 7- | tr -d "\n\r"`
   name="${name//'"'/\\\"}"

   vers=`echo "$debInfo" | grep "Version: " | cut -c 10- | tr -d "\n\r"`
   vers="${vers//'"'/\\\"}"

   author=`echo "$debInfo" | grep "Author: " | cut -c 9- | tr -d "\n\r"`
   author="${author//'"'/\\\"}"

   depends=`echo "$debInfo" | grep "Depends: " | cut -c 10- | tr -d "\n\r"`
   depends="${depends//'"'/\\\"}"

   description=`echo "$debInfo" | grep "Description: " | cut -c 14- | tr -d "\n\r"`
   description="${description//'"'/\\\"}"

   arch=`echo "$debInfo" | grep "Architecture: " | cut -c 15- | tr -d "\n\r"`
   arch="${arch//'"'/\\\"}"

   size=$(du -b $i | cut -f1)
   time=$(date +%s -r $i)
    
   echo '{"Name":"'$name'","Version":"'$vers'","Section":"'$section'","Package":"'$pkg'","Author":"'$author'","Depends":"'$depends'","Descript":"'$description'","Arch":"'$arch'","Size":"'$size'","Time":"'$time'000"},' >> all.pkgs  # update.ps1
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
#Building to json done==============
  leng=${#pkg}
  leng=`expr $leng + 1`
  exists=`echo "$compatity" | grep "$pkg " | cut -c "$leng"- | tr -d "\n\r"`
  if [[ -z $exists ]]; then
     echo "$pkg ($name)? "
     read tmp
     echo "$pkg $tmp" >> compatity.txt;
  fi
done
  
  echo "{}]" >> all.pkgs
}

echo "------------------"
echo "Building Packages...."
if ! command -v apt-ftparchive &> /dev/null; then
    echo "Error: apt-ftparchive not found!"
    exit 1
fi

# Tạo Packages
apt-ftparchive packages ./debs > ./Packages;

# Tạo các phiên bản nén
bzip2 -c9k ./Packages > ./Packages.bz2;
gzip -c9k ./Packages > ./Packages.gz;

echo "------------------"
echo "Building Release...."
# Tính toán các hash
PKG_MD5=$(md5sum ./Packages | cut -d ' ' -f 1)
PKG_SIZE=$(stat ./Packages --printf="%s")
PKG_BZ2_MD5=$(md5sum ./Packages.bz2 | cut -d ' ' -f 1)
PKG_BZ2_SIZE=$(stat ./Packages.bz2 --printf="%s")
PKG_GZ_MD5=$(md5sum ./Packages.gz | cut -d ' ' -f 1)
PKG_GZ_SIZE=$(stat ./Packages.gz --printf="%s")

PKG_SHA256=$(sha256sum ./Packages | cut -d ' ' -f 1)
PKG_BZ2_SHA256=$(sha256sum ./Packages.bz2 | cut -d ' ' -f 1)
PKG_GZ_SHA256=$(sha256sum ./Packages.gz | cut -d ' ' -f 1)

# Tạo file Release
cat > Release << EOF
Origin: Kho Lưu Trữ Romlayvn
Label: Kho Tinh Chỉnh iOS
Suite: stable
Version: 2.0
Codename: ios
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: Kho Tinh Chỉnh iOS Hiện Đại
MD5Sum:
 $PKG_MD5 $PKG_SIZE Packages
 $PKG_BZ2_MD5 $PKG_BZ2_SIZE Packages.bz2
 $PKG_GZ_MD5 $PKG_GZ_SIZE Packages.gz
SHA256:
 $PKG_SHA256 $PKG_SIZE Packages
 $PKG_BZ2_SHA256 $PKG_BZ2_SIZE Packages.bz2
 $PKG_GZ_SHA256 $PKG_GZ_SIZE Packages.gz
EOF

echo "------------------"
echo "Done!"
exit 0;