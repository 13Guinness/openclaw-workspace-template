#!/bin/bash
# setup-testing.sh — Scaffold Vitest + Playwright into a bare Next.js project.
# macOS bash 3.2 compatible (no associative arrays, no [[ regex =~ ]])
# Usage:
#   bash setup-testing.sh

set -e

# ── Locate project root ────────────────────────────────────────────────────────
find_project_root() {
  local dir
  dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo ""
}

PROJECT_ROOT="$(find_project_root)"
if [ -z "$PROJECT_ROOT" ]; then
  echo "Error: could not find package.json. Run this script from inside a Next.js project." >&2
  exit 1
fi

echo "Project root: $PROJECT_ROOT"

# ── Verify it looks like a Next.js project ─────────────────────────────────────
if ! grep -q '"next"' "$PROJECT_ROOT/package.json"; then
  echo "Warning: 'next' not found in package.json. This script targets Next.js projects." >&2
  printf "Continue anyway? [y/N] "
  read -r CONFIRM
  if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Detect package manager ─────────────────────────────────────────────────────
detect_pkg_manager() {
  if [ -f "$PROJECT_ROOT/bun.lockb" ] || [ -f "$PROJECT_ROOT/bun.lock" ]; then
    echo "bun"
  elif [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "$PROJECT_ROOT/yarn.lock" ]; then
    echo "yarn"
  else
    echo "npm"
  fi
}

PKG_MANAGER="$(detect_pkg_manager)"
echo "Package manager: $PKG_MANAGER"

# ── Detect TypeScript ──────────────────────────────────────────────────────────
USE_TS=0
if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  USE_TS=1
  echo "TypeScript detected."
fi

# ── Detect src/ layout ────────────────────────────────────────────────────────
SRC_DIR=""
if [ -d "$PROJECT_ROOT/src" ]; then
  SRC_DIR="src/"
fi

# ── Install command helper ─────────────────────────────────────────────────────
pkg_add() {
  # $1 = "dev" or "prod", remaining = package names
  local mode="$1"
  shift
  local packages="$*"

  case "$PKG_MANAGER" in
    bun)
      if [ "$mode" = "dev" ]; then
        bun add --dev $packages
      else
        bun add $packages
      fi
      ;;
    pnpm)
      if [ "$mode" = "dev" ]; then
        pnpm add --save-dev $packages
      else
        pnpm add $packages
      fi
      ;;
    yarn)
      if [ "$mode" = "dev" ]; then
        yarn add --dev $packages
      else
        yarn add $packages
      fi
      ;;
    *)
      if [ "$mode" = "dev" ]; then
        npm install --save-dev $packages
      else
        npm install $packages
      fi
      ;;
  esac
}

# ── Step 1: Install Vitest + Testing Library ──────────────────────────────────
echo ""
echo "── Installing Vitest + Testing Library ──────────────────────────────────────"
cd "$PROJECT_ROOT"

VITEST_PACKAGES="vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event"

if [ "$USE_TS" -eq 1 ]; then
  VITEST_PACKAGES="$VITEST_PACKAGES @types/testing-library__jest-dom"
fi

pkg_add dev $VITEST_PACKAGES
echo "Vitest packages installed."

# ── Step 2: Install Playwright ─────────────────────────────────────────────────
echo ""
echo "── Installing Playwright ────────────────────────────────────────────────────"
pkg_add dev @playwright/test
echo "Playwright package installed."
echo "Installing Playwright browsers (chromium only for speed)..."
npx playwright install chromium
echo "Playwright browser installed."

# ── Step 3: Create vitest.config.ts ──────────────────────────────────────────
echo ""
echo "── Writing vitest.config.ts ─────────────────────────────────────────────────"
VITEST_CONFIG="$PROJECT_ROOT/vitest.config.ts"

if [ -f "$VITEST_CONFIG" ]; then
  echo "vitest.config.ts already exists, skipping."
else
  cat > "$VITEST_CONFIG" << 'VITESTEOF'
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/__tests__/**/*.{test,spec}.{ts,tsx}', '**/*.{test,spec}.{ts,tsx}'],
    exclude: ['e2e/**', 'node_modules/**', '.next/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        '.next/',
        'e2e/',
        '**/*.config.{ts,js}',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 70,
        statements: 80,
      },
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
})
VITESTEOF
  echo "Created vitest.config.ts"
fi

# ── Step 4: Create vitest.setup.ts ────────────────────────────────────────────
VITEST_SETUP="$PROJECT_ROOT/vitest.setup.ts"
if [ -f "$VITEST_SETUP" ]; then
  echo "vitest.setup.ts already exists, skipping."
else
  cat > "$VITEST_SETUP" << 'SETUPEOF'
import '@testing-library/jest-dom'
import { vi } from 'vitest'

// Mock next/navigation for all tests
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    prefetch: vi.fn(),
    back: vi.fn(),
    forward: vi.fn(),
    refresh: vi.fn(),
    pathname: '/',
    query: {},
  }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams(),
  useParams: () => ({}),
  redirect: vi.fn(),
  notFound: vi.fn(),
}))

// Polyfill TextEncoder/TextDecoder if missing (Node < 18)
if (typeof globalThis.TextEncoder === 'undefined') {
  const { TextEncoder, TextDecoder } = require('util')
  globalThis.TextEncoder = TextEncoder
  globalThis.TextDecoder = TextDecoder
}
SETUPEOF
  echo "Created vitest.setup.ts"
fi

# ── Step 5: Create playwright.config.ts ───────────────────────────────────────
echo ""
echo "── Writing playwright.config.ts ─────────────────────────────────────────────"
PW_CONFIG="$PROJECT_ROOT/playwright.config.ts"

if [ -f "$PW_CONFIG" ]; then
  echo "playwright.config.ts already exists, skipping."
else
  cat > "$PW_CONFIG" << 'PWEOF'
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  timeout: 30000,
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
PWEOF
  echo "Created playwright.config.ts"
fi

# ── Step 6: Add test scripts to package.json ──────────────────────────────────
echo ""
echo "── Updating package.json scripts ────────────────────────────────────────────"
# Use node to safely update package.json
node -e "
var fs = require('fs');
var pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
var changed = false;
var additions = {
  'test': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
  'test:e2e': 'playwright test',
  'test:e2e:ui': 'playwright test --ui'
};
for (var key in additions) {
  if (!pkg.scripts[key]) {
    pkg.scripts[key] = additions[key];
    changed = true;
    console.log('Added script: ' + key);
  } else {
    console.log('Script already exists (skipped): ' + key);
  }
}
if (changed) {
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
  console.log('package.json updated.');
}
"

# ── Step 7: Create __tests__/ directory and example tests ─────────────────────
echo ""
echo "── Scaffolding __tests__/ ────────────────────────────────────────────────────"
TESTS_DIR="$PROJECT_ROOT/__tests__"
mkdir -p "$TESTS_DIR"

COMPONENT_TEST="$TESTS_DIR/example.component.test.tsx"
if [ -f "$COMPONENT_TEST" ]; then
  echo "example.component.test.tsx already exists, skipping."
else
  cat > "$COMPONENT_TEST" << 'COMPEOF'
/**
 * Example component test — replace with your actual component.
 * This file demonstrates Testing Library patterns for Next.js components.
 */
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'

// Example: a simple Button component
// import Button from '@/components/Button'

// Inline stub so this test runs without a real component
function Button({
  children,
  onClick,
}: {
  children: React.ReactNode
  onClick?: () => void
}) {
  return <button onClick={onClick}>{children}</button>
}

describe('Button (example)', () => {
  it('renders its label', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>Click</Button>)
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledOnce()
  })

  it('does not call onClick when not clicked', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>No click</Button>)
    expect(handleClick).not.toHaveBeenCalled()
  })
})
COMPEOF
  echo "Created __tests__/example.component.test.tsx"
fi

API_TEST="$TESTS_DIR/example.api.test.ts"
if [ -f "$API_TEST" ]; then
  echo "example.api.test.ts already exists, skipping."
else
  cat > "$API_TEST" << 'APIEOF'
/**
 * Example API route test — demonstrates testing Next.js App Router route handlers.
 * Replace with imports from your actual route files.
 */
import { describe, it, expect } from 'vitest'
import { NextRequest } from 'next/server'

// Inline stub handler — replace with: import { GET } from '@/app/api/hello/route'
async function GET(_req: NextRequest): Promise<Response> {
  return new Response(JSON.stringify({ message: 'Hello, world!' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
}

describe('GET /api/hello (example)', () => {
  it('returns 200 with a message', async () => {
    const req = new NextRequest('http://localhost:3000/api/hello')
    const res = await GET(req)
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body).toHaveProperty('message')
    expect(body.message).toBe('Hello, world!')
  })

  it('responds with JSON content-type', async () => {
    const req = new NextRequest('http://localhost:3000/api/hello')
    const res = await GET(req)
    expect(res.headers.get('content-type')).toContain('application/json')
  })
})
APIEOF
  echo "Created __tests__/example.api.test.ts"
fi

# ── Step 8: Create e2e/ directory and example Playwright test ─────────────────
echo ""
echo "── Scaffolding e2e/ ─────────────────────────────────────────────────────────"
E2E_DIR="$PROJECT_ROOT/e2e"
mkdir -p "$E2E_DIR"

E2E_TEST="$E2E_DIR/example.spec.ts"
if [ -f "$E2E_TEST" ]; then
  echo "example.spec.ts already exists, skipping."
else
  cat > "$E2E_TEST" << 'E2EEOF'
/**
 * Example Playwright E2E test.
 * Assumes the dev server is running on http://localhost:3000.
 * playwright.config.ts webServer config will start it automatically.
 */
import { test, expect } from '@playwright/test'

test.describe('Homepage', () => {
  test('loads successfully', async ({ page }) => {
    await page.goto('/')
    // Verify the page responded (no 404/500)
    const status = page.url()
    expect(status).toContain('localhost:3000')
  })

  test('has a visible heading', async ({ page }) => {
    await page.goto('/')
    // Next.js default page has an <h1>; adjust selector for your app
    const heading = page.locator('h1')
    await expect(heading).toBeVisible()
  })
})

test.describe('Navigation', () => {
  test('can navigate with browser back/forward', async ({ page }) => {
    await page.goto('/')
    const initialUrl = page.url()
    // Navigate somewhere (adjust href for your app)
    const links = page.locator('a[href]')
    const count = await links.count()
    if (count > 0) {
      const href = await links.first().getAttribute('href')
      if (href && href.startsWith('/') && href !== '/') {
        await page.click(`a[href="${href}"]`)
        await page.goBack()
        expect(page.url()).toBe(initialUrl)
      }
    }
  })
})
E2EEOF
  echo "Created e2e/example.spec.ts"
fi

# ── Step 9: Update .gitignore ─────────────────────────────────────────────────
GITIGNORE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
  GITIGNORE_ENTRIES="
# Test artifacts
coverage/
playwright-report/
test-results/
"
  if ! grep -q "playwright-report" "$GITIGNORE"; then
    printf '%s\n' "$GITIGNORE_ENTRIES" >> "$GITIGNORE"
    echo "Updated .gitignore with test artifact entries."
  else
    echo ".gitignore already has test entries, skipping."
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo " Testing setup complete!"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo " Files created:"
echo "   vitest.config.ts"
echo "   vitest.setup.ts"
echo "   playwright.config.ts"
echo "   __tests__/example.component.test.tsx"
echo "   __tests__/example.api.test.ts"
echo "   e2e/example.spec.ts"
echo ""
echo " Scripts added to package.json:"
echo "   test          — vitest run (unit, once)"
echo "   test:watch    — vitest (watch mode)"
echo "   test:coverage — vitest run --coverage"
echo "   test:e2e      — playwright test"
echo "   test:e2e:ui   — playwright test --ui"
echo ""
echo " Next steps:"
echo "   1. Run unit tests:    bash scripts/run-tests.sh"
echo "   2. Run with coverage: bash scripts/run-tests.sh --coverage"
echo "   3. Run E2E tests:     bash scripts/run-tests.sh (starts dev server)"
echo "   4. Replace example tests with tests for your actual components"
echo "══════════════════════════════════════════════════════════════"

exit 0
