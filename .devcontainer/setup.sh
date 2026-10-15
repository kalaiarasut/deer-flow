#!/usr/bin/env bash
set -e

echo "=========================================="
echo "  Setting up DeerFlow GitHub Workspace"
echo "=========================================="

# 1. Install system prerequisites (nginx)
echo "Installing Nginx..."
sudo apt-get update -qq
sudo apt-get install -y -qq nginx

# 2. Setup pnpm
echo "Setting up pnpm..."
corepack enable || true
npm install -g pnpm@10.26.2

# 3. Install uv
echo "Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
if [ -f "$HOME/.local/bin/uv" ] && [ ! -f /usr/local/bin/uv ]; then
    sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv || true
fi

# 4. Generate local configuration files
echo "Configuring environment..."
python3 scripts/configure.py || true

# Ensure Codespaces dev origins and binding are configured in frontend/.env
if [ -f "frontend/.env" ]; then
    if ! grep -q "DEER_FLOW_DEV_ALLOWED_ORIGINS" frontend/.env; then
        echo 'DEER_FLOW_DEV_ALLOWED_ORIGINS="*.app.github.dev,*.github.dev"' >> frontend/.env
    fi
fi

# 5. Install backend dependencies
echo "Installing backend dependencies..."
(cd backend && uv sync --locked)

# 6. Install frontend dependencies
echo "Installing frontend dependencies..."
(cd frontend && pnpm install)

# 7. Preflight checks
echo "Verifying environment..."
python3 scripts/check.py || true

echo ""
echo "=========================================="
echo "  ✓ Setup complete!"
echo "  Start DeerFlow with: make dev"
echo "  Then open port 2026 in the browser"
echo "=========================================="
