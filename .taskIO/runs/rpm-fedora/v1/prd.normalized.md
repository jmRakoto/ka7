# Paquet .rpm pour Fedora

## Contexte

Ka7 sort pour Linux en `.deb` (Ubuntu, Debian) et en AppImage, construits par
`tool/package_linux.sh` dans un conteneur Ubuntu 22.04. Les distributions de la
famille Fedora (Fedora, et par extension RHEL, AlmaLinux, Rocky, openSUSE) ne
savent pas installer un `.deb` : leurs utilisateurs n'ont que l'AppImage, sans
entrée de menu ni commande `ka7`, et sans mise à jour par le gestionnaire de
paquets.

## Objectif

Produire, à chaque version, un `ka7-<version>-1.x86_64.rpm` qui fait pour Fedora
ce que fait le `.deb` : l'app (`ka7-app`, entrée de menu, icônes) et la commande
`ka7`, installés par `sudo dnf install ./ka7-<version>-1.x86_64.rpm`.

## Exigences

- Même contenu que le `.deb` : `/opt/ka7/app` (avec la libmpv LGPL de Ka7 et ses
  licences), `/opt/ka7/cli`, liens `/usr/bin/ka7-app` et `/usr/bin/ka7`, fichier
  `.desktop` et icônes.
- Dépendances aux noms Fedora : gtk3, pulseaudio-libs, alsa-lib, gnutls, xz,
  xdg-utils, zenity ou kdialog.
- Construit dans le même conteneur Ubuntu 22.04 que les autres paquets
  (`rpmbuild`), reproductible comme eux (`SOURCE_DATE_EPOCH`).
- Vérifié dans un conteneur Fedora propre avant chaque version : installation
  par `dnf`, app debout 15 s, la libmpv de Ka7 chargée, `ka7 --help` répond.
- Publié avec la release et cité dans le guide d'installation des notes, avec
  son empreinte SHA-256.

## Hors périmètre

Dépôt dnf (COPR) et signature GPG du paquet, Flatpak, autres architectures que
x86_64.
