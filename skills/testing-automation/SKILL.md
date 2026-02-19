---
name: testing-automation
description: Run and scaffold Jest, Playwright, and Vitest tests for Next.js apps. Use when setting up testing, running test suites, debugging failing tests, or adding test coverage.
version: 1.0
category: testing
---

# Testing Automation Skill

Automates test setup, discovery, and execution for Next.js projects using Jest, Vitest, or Playwright.

## When to Use

- Setting up a testing framework in a bare Next.js project
- Running unit, integration, or end-to-end test suites
- Debugging failing tests and interpreting output
- Adding test coverage reporting
- Scaffolding example tests for API routes or React components

## Available Scripts

| Script | Purpose |
|---|---|
| `scripts/run-tests.sh` | Auto-detect framework & run tests |
| `scripts/setup-testing.sh` | Scaffold Vitest + Playwright into a bare Next.js project |

---

## Auto-Detecting the Test Framework

Detection order (checks `package.json` `dependencies` + `devDependencies`):

1. **Vitest** — key: `vitest`
2. **Jest** — key: `jest`
3. **Playwright** — key: `@playwright/test`

If multiple are present, unit tests (Vitest/Jest) run first; Playwright runs as a separate step.

---

## Running Tests

```bash
# Run all tests (auto-detects framework + package manager)
bash scripts/run-tests.sh

# Run tests for a specific path
bash scripts/run-tests.sh --path src/components/Button

# Run with coverage
bash scripts/run-tests.sh --coverage

# Combine flags
bash scripts/run-tests.sh --path src/api --coverage
```

The script detects your package manager (`bun`, `pnpm`, `yarn`, or `npm`) from lockfiles in the project root.

---

## Scaffolding a Test Setup

```bash
# Scaffold Vitest + Playwright into a bare Next.js project
bash scripts/setup-testing.sh
```

Creates:
```
vitest.config.ts
playwright.config.ts
__tests__/
  example.component.test.tsx
  example.api.test.ts
e2e/
  example.spec.ts
```

---

## Next.js Test Patterns

### API Route (App Router)

```ts
// __tests__/api/hello.test.ts
import { GET } from '@/app/api/hello/route'
import { NextRequest } from 'next/server'

describe('GET /api/hello', () => {
  it('returns 200 with greeting', async () => {
    const req = new NextRequest('http://localhost/api/hello')
    const res = await GET(req)
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body).toHaveProperty('message')
  })
})
```

### API Route (Pages Router)

```ts
// __tests__/api/hello.test.ts
import { createMocks } from 'node-mocks-http'
import handler from '@/pages/api/hello'

describe('GET /api/hello', () => {
  it('returns 200', () => {
    const { req, res } = createMocks({ method: 'GET' })
    handler(req, res)
    expect(res._getStatusCode()).toBe(200)
  })
})
```

### React Component (Vitest + Testing Library)

```tsx
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import Button from '@/components/Button'

describe('Button', () => {
  it('renders label', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument()
  })

  it('calls onClick handler', () => {
    const onClick = vi.fn()
    render(<Button onClick={onClick}>Click</Button>)
    fireEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledOnce()
  })
})
```

### React Component (Jest + Testing Library)

```tsx
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import Button from '@/components/Button'

describe('Button', () => {
  it('renders label', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument()
  })

  it('calls onClick handler', () => {
    const onClick = jest.fn()
    render(<Button onClick={onClick}>Click</Button>)
    fireEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledTimes(1)
  })
})
```

### Server Component (Vitest)

```tsx
// __tests__/components/UserCard.test.tsx
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import UserCard from '@/components/UserCard'

// Server Components render synchronously in tests
describe('UserCard', () => {
  it('displays user name', () => {
    render(<UserCard name="Alice" role="Admin" />)
    expect(screen.getByText('Alice')).toBeInTheDocument()
    expect(screen.getByText('Admin')).toBeInTheDocument()
  })
})
```

### Playwright E2E

```ts
// e2e/homepage.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Homepage', () => {
  test('loads and shows heading', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveTitle(/My App/)
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
  })

  test('navigation works', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: /about/i }).click()
    await expect(page).toHaveURL('/about')
  })
})
```

### Mocking `next/navigation` (Vitest)

```ts
// vitest.setup.ts  (referenced in vitest.config.ts setupFiles)
import { vi } from 'vitest'

vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    prefetch: vi.fn(),
    back: vi.fn(),
    pathname: '/',
    query: {},
  }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams(),
}))
```

### Mocking `next/navigation` (Jest)

```ts
// jest.setup.ts
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
    replace: jest.fn(),
    prefetch: jest.fn(),
    back: jest.fn(),
    pathname: '/',
    query: {},
  }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams(),
}))
```

---

## Coverage Reporting

### Vitest

```bash
bash scripts/run-tests.sh --coverage
# Outputs: coverage/index.html  (open in browser)
# Also prints summary to terminal
```

Config threshold example (`vitest.config.ts`):
```ts
coverage: {
  thresholds: { lines: 80, functions: 80, branches: 70, statements: 80 }
}
```

### Jest

```bash
bash scripts/run-tests.sh --coverage
# Outputs: coverage/lcov-report/index.html
```

Config threshold example (`jest.config.ts`):
```ts
coverageThreshold: {
  global: { lines: 80, functions: 80, branches: 70, statements: 80 }
}
```

---

## Debugging Failing Tests

Common Next.js test pitfalls and fixes:

| Problem | Fix |
|---|---|
| `Cannot find module '@/...'` | Add `moduleNameMapper` (Jest) or `resolve.alias` (Vitest) pointing `@` to `<rootDir>/src` or `<rootDir>` |
| `useRouter` is not a function | Mock `next/navigation` in setup file (see patterns above) |
| Server component async errors | Wrap in `React.Suspense` or test with `renderToString` |
| `TextEncoder is not defined` | Add `import { TextEncoder } from 'util'` to jest/vitest setup |
| Playwright timeout on CI | Increase `timeout` in `playwright.config.ts`; ensure `webServer` is configured |
| `fetch is not defined` | Use `node-fetch` polyfill or Node 18+ (native fetch available) |

---

## CI Integration

### GitHub Actions snippet

```yaml
- name: Run unit tests
  run: bash .openclaw/workspace/skills/testing-automation/scripts/run-tests.sh --coverage

- name: Run E2E tests
  run: |
    npx playwright install --with-deps
    bash .openclaw/workspace/skills/testing-automation/scripts/run-tests.sh
```
