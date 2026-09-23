# ../../home/lib/adwaita-grey-folders.nix
#
# Adwaita with grey, not blue, folder icons. Desktop-agnostic (Inherits=
# Adwaita, only the folder-equivalent SVGs are touched) - shared by any
# home config that wants it (home/niri.nix, home/gnome.nix), not
# duplicated per-stack. Activated via dconf
# org/gnome/desktop/interface icon-theme in the consuming file.
{ runCommand, adwaita-icon-theme }:

runCommand "adwaita-grey-folders" { } ''
  mkdir -p $out/share/icons/Adwaita-Grey-Folders/scalable/{places,status,mimetypes}

  recolor() {
    sed \
      -e 's/#438de6/#77767b/g' \
      -e 's/#62a0ea/#9a9996/g' \
      -e 's/#a4caee/#9a9996/g' \
      -e 's/#afd4ff/#c0bfbc/g' \
      -e 's/#c0d5ea/#aeadab/g' \
      "$1" > "$2"
  }

  for f in folder folder-documents folder-download folder-music \
           folder-pictures folder-videos folder-publicshare \
           folder-templates folder-remote folder-drag-accept \
           user-desktop user-home user-bookmarks; do
    recolor \
      "${adwaita-icon-theme}/share/icons/Adwaita/scalable/places/$f.svg" \
      "$out/share/icons/Adwaita-Grey-Folders/scalable/places/$f.svg"
  done

  recolor \
    "${adwaita-icon-theme}/share/icons/Adwaita/scalable/status/folder-open.svg" \
    "$out/share/icons/Adwaita-Grey-Folders/scalable/status/folder-open.svg"

  recolor \
    "${adwaita-icon-theme}/share/icons/Adwaita/scalable/mimetypes/inode-directory.svg" \
    "$out/share/icons/Adwaita-Grey-Folders/scalable/mimetypes/inode-directory.svg"

  cat > $out/share/icons/Adwaita-Grey-Folders/index.theme << 'EOF'
[Icon Theme]
Name=Adwaita-Grey-Folders
Comment=Adwaita with grey, not blue, folder icons
Inherits=Adwaita
Directories=scalable/places,scalable/status,scalable/mimetypes

[scalable/places]
Size=128
Type=Scalable
MinSize=8
MaxSize=512
Context=Places

[scalable/status]
Size=128
Type=Scalable
MinSize=8
MaxSize=512
Context=Status

[scalable/mimetypes]
Size=128
Type=Scalable
MinSize=8
MaxSize=512
Context=MimeTypes
EOF
''
