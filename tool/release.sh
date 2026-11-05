#!/usr/bin/env bash
# Publishes a Ka7 version on GitHub Releases, from start to end:
#   checks → tool/check.sh → Linux and Android packages → signature check
#   → notes (yours + install guide + SHA-256) → tag v<version> → upload
#   → downloads each file back and compares it.
#
# Usage:
#   tool/release.sh notes.md             publish the version of app/pubspec.yaml
#   tool/release.sh --dry-run notes.md   everything but the tag and the upload
#
# notes.md holds only what is new (the « Nouveautés » part); the install
# guide and the checksums are added here, from the files actually uploaded.
#
# Windows: built afterwards on GitHub (.github/workflows/windows.yml, started
# by the published release), which adds its files and notes to the release.
#
# Before: raise `version:` in app/pubspec.yaml (and its +N) and in
# cli/pubspec.yaml, commit, push.
set -euo pipefail

dry_run=false
if [[ ${1:-} == --dry-run ]]; then
  dry_run=true
  shift
fi
if [[ $# -ne 1 || ! -f $1 ]]; then
  echo "Usage: tool/release.sh [--dry-run] notes.md" >&2
  exit 2
fi
# Read where the user stands, before moving to the project root.
news=$(realpath "$1")
cd "$(dirname "$0")/.."

fail() {
  echo "✗ $*" >&2
  exit 1
}
step() { echo "== $*"; }

version=$(sed -n 's/^version: \([0-9.]*\)+[0-9]*$/\1/p' app/pubspec.yaml)
build=$(sed -n 's/^version: [0-9.]*+\([0-9]*\)$/\1/p' app/pubspec.yaml)
cli_version=$(sed -n 's/^version: \([0-9.]*\)$/\1/p' cli/pubspec.yaml)
tag=v$version
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)

step "Ka7 $version (build $build) → $repo"

# --- Checks before anything long -------------------------------------------
[[ -n $version && -n $build ]] ||
  fail "app/pubspec.yaml: version attendue sous la forme 1.2.3+4"
[[ $cli_version == "$version" ]] ||
  fail "cli/pubspec.yaml est en $cli_version, l'app en $version"
gh auth status >/dev/null 2>&1 || fail "gh n'est pas connecté : gh auth login"

key_properties=${KA7_KEY_PROPERTIES:-$HOME/.config/ka7/key.properties}
# Without it Gradle signs with the debug key: such an APK cannot update
# anyone's install.
[[ -f $key_properties ]] ||
  fail "clé de publication introuvable ($key_properties)"

if ! $dry_run; then
  [[ -z $(git status --porcelain) ]] ||
    fail "des changements ne sont pas commités"
  git fetch -q --tags origin
  [[ $(git rev-parse HEAD) == "$(git rev-parse '@{u}')" ]] ||
    fail "la branche n'est pas à jour avec origin : git pull / git push"
  ! git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null ||
    fail "$tag existe déjà sur GitHub : augmente la version"
  previous=$(gh release view -R "$repo" --json tagName -q .tagName 2>/dev/null || true)
  if [[ -n $previous ]]; then
    last_build=$(git show "$previous:app/pubspec.yaml" 2>/dev/null |
      sed -n 's/^version: [0-9.]*+\([0-9]*\)$/\1/p')
    [[ -z $last_build || $build -gt $last_build ]] ||
      fail "build +$build pas plus grand que +$last_build ($previous) : Android refuserait la mise à jour"
  fi
fi

# --- Gate and packages ------------------------------------------------------
step "Vérifications (tool/check.sh)"
tool/check.sh

step "Paquets Linux"
tool/package_linux.sh
step "Paquets Android"
tool/package_android.sh

files=(
  "dist/Ka7-$version-arm64-v8a.apk"
  "dist/Ka7-$version-armeabi-v7a.apk"
  "dist/ka7_${version}_amd64.deb"
  "dist/Ka7-$version-x86_64.AppImage"
)
for file in "${files[@]}"; do
  [[ -f $file ]] || fail "$file n'a pas été produit"
done

step "Signature des APK"
apksigner=$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/apksigner |
  sort -V | tail -1)
for apk in "${files[@]:0:2}"; do
  signer=$("$apksigner" verify --print-certs "$apk" |
    sed -n 's/^Signer #1 certificate DN: //p')
  [[ -n $signer && $signer != *"Android Debug"* ]] ||
    fail "$apk n'est pas signé avec la clé de publication ($signer)"
  echo "   $(basename "$apk") : $signer"
done

# --- Notes, checksums taken from the files about to be sent -----------------
notes=$(mktemp --suffix=.md)
trap 'rm -f "$notes"' EXIT
{
  cat "$news"
  cat <<EOF

## Installer

### Android (7 ou plus récent)

1. Sur le téléphone, télécharge **\`Ka7-$version-arm64-v8a.apk\`** ci-dessous (bon choix pour presque tous les téléphones depuis 2017).
2. Ouvre le fichier. Android demande d'autoriser l'installation depuis cette source (Chrome, Fichiers…) : accepte.
3. Lance Ka7.

Si Android affiche « app non compatible », prends **\`Ka7-$version-armeabi-v7a.apk\`** (vieux téléphones 32 bits).

Tu avais une version précédente ? Installe simplement par-dessus : ton historique est gardé.

Les fichiers arrivent dans les dossiers **Music/Ka7** et **Movies/Ka7**, visibles par toutes les apps de musique.

### Linux (64 bits)

- **Ubuntu, Debian** : télécharge \`ka7_${version}_amd64.deb\`, puis
  \`\`\`bash
  sudo apt install ./ka7_${version}_amd64.deb
  \`\`\`
  Tu as l'app (« Ka7 » dans le menu) et la commande \`ka7\`.
- **Autre distribution** : télécharge \`Ka7-$version-x86_64.AppImage\`, puis
  \`\`\`bash
  chmod +x Ka7-$version-x86_64.AppImage
  ./Ka7-$version-x86_64.AppImage
  \`\`\`

Au premier lancement, l'app propose d'installer yt-dlp et ffmpeg (environ 180 Mo, une seule fois).

## Empreintes SHA-256

\`\`\`
EOF
  for file in "${files[@]}"; do
    (cd dist && sha256sum "$(basename "$file")")
  done
  echo '```'
} >"$notes"

if $dry_run; then
  cp "$notes" "dist/release-notes-$version.md"
  step "Essai à blanc : rien publié"
  echo "   Notes : dist/release-notes-$version.md"
  printf '   %s\n' "${files[@]}"
  exit 0
fi

# --- Publish, then check what GitHub holds ----------------------------------
step "Publication de $tag"
gh release create "$tag" -R "$repo" --target "$(git rev-parse HEAD)" \
  --title "Ka7 $version" --notes-file "$notes" "${files[@]}"

step "Contrôle des fichiers publiés"
check=$(mktemp -d)
trap 'rm -f "$notes"; rm -rf "$check"' EXIT
gh release download "$tag" -R "$repo" -D "$check"
for file in "${files[@]}"; do
  name=$(basename "$file")
  [[ $(sha256sum <"$check/$name") == "$(sha256sum <"$file")" ]] ||
    fail "$name publié diffère de $file"
  echo "   $name ✓"
done

step "Publié : https://github.com/$repo/releases/tag/$tag"
