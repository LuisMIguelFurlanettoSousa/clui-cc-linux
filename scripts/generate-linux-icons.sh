#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# generate-linux-icons.sh
#
# Gera ícones PNG em múltiplos tamanhos a partir de resources/icon.png
# para uso no Electron no Linux (tray, dock, .desktop, etc.)
#
# Tamanhos padrão: 16, 32, 48, 64, 128, 256, 512
# Saída: resources/icons/<tamanho>x<tamanho>.png
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE="$PROJECT_ROOT/resources/icon.png"
OUTPUT_DIR="$PROJECT_ROOT/resources/icons"

SIZES=(16 32 48 64 128 256 512)

# Verifica se o ícone fonte existe
if [ ! -f "$SOURCE" ]; then
  echo "ERRO: Arquivo fonte não encontrado em $SOURCE"
  exit 1
fi

# Verifica se ImageMagick está disponível
if ! command -v convert &>/dev/null; then
  echo "─────────────────────────────────────────────────────"
  echo "ImageMagick (convert) não está instalado."
  echo ""
  echo "Para instalar no Ubuntu/Debian:"
  echo "  sudo apt install imagemagick"
  echo ""
  echo "Para instalar no Fedora:"
  echo "  sudo dnf install ImageMagick"
  echo ""
  echo "Para instalar no Arch:"
  echo "  sudo pacman -S imagemagick"
  echo "─────────────────────────────────────────────────────"
  echo ""
  echo "Pulando geração de ícones. O app usará o icon.png original."
  exit 0
fi

# Cria o diretório de saída
mkdir -p "$OUTPUT_DIR"

echo "Gerando ícones Linux a partir de $SOURCE..."

for size in "${SIZES[@]}"; do
  output="$OUTPUT_DIR/${size}x${size}.png"
  convert "$SOURCE" -resize "${size}x${size}" "$output"
  echo "  ✔ ${size}x${size}.png"
done

echo ""
echo "Ícones gerados com sucesso em $OUTPUT_DIR/"
