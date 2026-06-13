#!/bin/bash
# LegacyBridge: Automated Compatibility Layer for ARMv8.0
# Installs Antigravity CLI (agy) em hardware ARM sem suporte a LSE
# https://github.com/Eddyruphay/LegacyBridge

set -euo pipefail

BINARY_NAME="antigravity"
INSTALL_DIR="/usr/local/bin"
WRAPPER_NAME="agy"
MANIFEST_URL="https://antigravity-cli-auto-updater-974.storage.googleapis.com/linux-arm/manifest.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[*]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Detecta se o CPU tem suporte a LSE ---
cpu_has_lse() {
    grep -q "atomics" /proc/cpuinfo 2>/dev/null
}

# --- Detecta versão mais recente dinamicamente ---
fetch_latest_url() {
    info "Consultando versão mais recente..."
    MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null) || error "Falha ao contactar servidor do Google."
    BINARY_URL=$(echo "$MANIFEST" | grep -oP '"url"\s*:\s*"\K[^"]+')
    VERSION=$(echo "$MANIFEST"    | grep -oP '"version"\s*:\s*"\K[^"]+')
    info "Versão encontrada: $VERSION"
}

# --- Download e extração ---
download_binary() {
    info "Baixando binário arm64..."
    curl -fsSL "$BINARY_URL" -o /tmp/agy.tar.gz
    tar xzf /tmp/agy.tar.gz -C /tmp
    # O binário pode chamar-se 'antigravity' ou 'agy'
    if [ -f /tmp/antigravity ]; then
        mv /tmp/antigravity "$INSTALL_DIR/$BINARY_NAME"
    elif [ -f /tmp/agy ]; then
        mv /tmp/agy "$INSTALL_DIR/$BINARY_NAME"
    else
        error "Binário não encontrado no arquivo. Conteúdo: $(ls /tmp/)"
    fi
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
}

# --- Instala QEMU se necessário ---
install_qemu() {
    if command -v qemu-aarch64 &>/dev/null; then
        QEMU_BIN=$(command -v qemu-aarch64)
        info "QEMU já instalado: $QEMU_BIN"
        return
    fi
    info "Instalando qemu-user..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq qemu-user
    elif command -v dnf &>/dev/null; then
        dnf install -y qemu-user
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm qemu-user
    else
        error "Gestor de pacotes não suportado. Instala qemu-user manualmente."
    fi
    QEMU_BIN=$(command -v qemu-aarch64)
}

# --- Cria wrapper transparente ---
create_wrapper() {
    local qemu_bin="$1"
    info "Criando wrapper transparente em $INSTALL_DIR/$WRAPPER_NAME..."
    cat > "$INSTALL_DIR/$WRAPPER_NAME" <<EOF
#!/bin/sh
# LegacyBridge wrapper — executa Antigravity CLI via QEMU em ARMv8.0
exec $qemu_bin $INSTALL_DIR/$BINARY_NAME "\$@"
EOF
    chmod +x "$INSTALL_DIR/$WRAPPER_NAME"
}

# --- Instala nativamente (sem QEMU) ---
install_native() {
    info "CPU suporta LSE — instalando nativamente..."
    ln -sf "$INSTALL_DIR/$BINARY_NAME" "$INSTALL_DIR/$WRAPPER_NAME"
}

# --- Verifica instalação ---
verify() {
    if "$INSTALL_DIR/$WRAPPER_NAME" --version &>/dev/null; then
        local ver
        ver=$("$INSTALL_DIR/$WRAPPER_NAME" --version 2>&1)
        info "✅ Instalação verificada: agy $ver"
    else
        warn "O binário foi instalado mas não respondeu ao --version. Tenta: agy"
    fi
}

# ============================================================
# MAIN
# ============================================================
echo ""
echo "  🌉 LegacyBridge — ARM64 Compatibility Installer"
echo "  ================================================"
echo ""

# Verifica root
[ "$(id -u)" -eq 0 ] || error "Executa como root: sudo bash install.sh"

# Verifica arquitetura
ARCH=$(uname -m)
[ "$ARCH" = "aarch64" ] || error "Este script é para aarch64. Detectado: $ARCH"

fetch_latest_url
download_binary

if cpu_has_lse; then
    info "CPU: ARMv8.1+ com LSE detectado."
    install_native
else
    warn "CPU: ARMv8.0 sem LSE (ex: Cortex-A53). Activando compatibilidade QEMU..."
    install_qemu
    create_wrapper "$QEMU_BIN"
fi

verify

echo ""
echo -e "  ${GREEN}Pronto! Usa o comando: agy${NC}"
echo ""
