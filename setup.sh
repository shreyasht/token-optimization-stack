#!/usr/bin/env bash
# ==============================================================================
# Token Optimization Stack — Automated Installer
# Curated open-source stack to optimize AI coding agent context and token spend.
# ==============================================================================

set -euo pipefail

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${BOLD}"
    echo "=========================================================="
    echo "   ⚡ Token Optimization Stack Installer"
    echo "=========================================================="
    echo -e "${NC}"
}

check_prerequisites() {
    info "Checking prerequisites..."
    
    if ! command -v python3 &>/dev/null; then
        error "Python 3 is required. Please install Python 3.10+ and re-run."
        exit 1
    fi

    if ! command -v curl &>/dev/null; then
        error "curl is required. Please install curl and re-run."
        exit 1
    fi

    if command -v uv &>/dev/null; then
        PIP_CMD="uv pip install"
        TOOL_CMD="uv tool install"
        info "Found 'uv' (fast Python package manager)."
    elif command -v pipx &>/dev/null; then
        PIP_CMD="pip install"
        TOOL_CMD="pipx install"
        info "Found 'pipx'."
    else
        PIP_CMD="pip install"
        TOOL_CMD="pip install"
        warn "Neither uv nor pipx detected. Defaulting to standard pip."
    fi
}

install_graphify() {
    info "Installing Graphify (Codebase Intelligence)..."
    if $TOOL_CMD graphifyy; then
        if command -v graphify &>/dev/null; then
            graphify install || true
            success "Graphify installed and agent skills configured."
        else
            warn "Graphify binary not found in PATH. Ensure your tool path is exported."
        fi
    else
        warn "Graphify installation encountered issues. Skipping..."
    fi
}

install_serena() {
    info "Installing Serena (Symbol-Level Navigation & Editing)..."
    if $TOOL_CMD serena-agent; then
        success "Serena installed."
    else
        warn "Serena installation failed."
    fi
}

install_caveman() {
    info "Installing Caveman (Output Compression Skill)..."
    if curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/v2.1.0/install.sh | bash; then
        success "Caveman skill installed."
    else
        warn "Caveman install script failed. Continuing with remaining tools..."
    fi
}

install_leanctx() {
    info "Installing LeanCTX (Context Layer & Memory)..."
    if curl -fsSL https://raw.githubusercontent.com/yvgude/lean-ctx/v3.9.19/install.sh | sh; then
        if command -v lean-ctx &>/dev/null; then
            lean-ctx setup || true
            success "LeanCTX installed and hooks initialized."
        fi
    else
        warn "LeanCTX installer failed. Skipping..."
    fi
}

install_agentsview() {
    info "Installing Agentsview (Token & Trace Monitoring)..."
    if $PIP_CMD agentsview; then
        success "Agentsview installed."
    else
        warn "Agentsview installation failed."
    fi
}

run_diagnostics() {
    echo ""
    info "Running post-install diagnostics..."

    command -v graphify &>/dev/null && echo -e "  - Graphify:    ${GREEN}OK${NC}" || echo -e "  - Graphify:    ${YELLOW}Not in PATH${NC}"
    command -v serena &>/dev/null && echo -e "  - Serena:      ${GREEN}OK${NC}" || echo -e "  - Serena:      ${YELLOW}Not in PATH${NC}"
    command -v lean-ctx &>/dev/null && echo -e "  - LeanCTX:     ${GREEN}OK${NC}" || echo -e "  - LeanCTX:     ${YELLOW}Not in PATH${NC}"
    command -v agentsview &>/dev/null && echo -e "  - Agentsview:  ${GREEN}OK${NC}" || echo -e "  - Agentsview:  ${YELLOW}Not in PATH${NC}"
}

main() {
    print_banner
    check_prerequisites

    echo ""
    echo "This script will install the open-source token optimization stack:"
    echo "  1. Graphify (Codebase Knowledge Graph)"
    echo "  2. Serena (Symbol-Level Navigation & Editing)"
    echo "  3. Caveman (Output Compression Skill)"
    echo "  4. LeanCTX (Context Layer & MCP Cache)"
    echo "  5. Agentsview (Token & Trace Observability)"
    echo ""

    install_graphify
    install_serena
    install_caveman
    install_leanctx
    install_agentsview

    run_diagnostics

    echo ""
    success "Setup complete! See TOKEN_OPTIMIZATION_STACK.md for configuration details."
}

main "$@"
