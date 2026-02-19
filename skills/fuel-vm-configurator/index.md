---
description: Fuel VM Configurator — Apple Store-style quote builder for custom hosting/server packages. Assemble quotes, email to clients, accept/reject workflow. Next.js + Prisma + NextAuth.
kind: skill-graph
topics: ["[[nextjs]]", "[[quote-management]]", "[[saas]]"]
---

# Fuel VM Configurator

Apple Store-style configurator for assembling custom hosting and server quotes.

## Purpose

**Problem:** Creating custom server/hosting quotes manually is time-consuming and error-prone.

**Solution:** Interactive configurator where you:
- Assemble packages (like building a Mac on apple.com)
- Generate professional quotes automatically
- Email quotes to clients
- Track accept/reject status

## Architecture

### Tech Stack
- **Frontend:** Next.js 16 + React 19
- **Backend:** Prisma + PostgreSQL (Neon)
- **Auth:** NextAuth v5
- **UI:** Tailwind CSS + shadcn/ui
- **Forms:** React Hook Form + Zod validation

### Key Components

- [[quote-builder]] — Interactive package assembly
- [[client-management]] — CRM for tracking clients
- [[email-system]] — Quote delivery and notifications
- [[pricing-engine]] — Dynamic pricing calculations
- [[auth-system]] — NextAuth-based authentication

## Core Features

### [[quote-builder]]
- Drag-and-drop package assembly
- Real-time pricing updates
- Package templates
- Custom line items

### [[client-management]]
- Client database
- Contact information
- Quote history per client
- Accept/reject tracking

### [[email-system]]
- Professional quote emails
- Client portal links
- Accept/reject buttons
- Automated follow-ups

### [[quote-workflow]]
- Draft → Sent → Accepted/Rejected
- Version history
- Quote expiration
- PDF generation

## Use Cases

### New Client Quote
1. Create client in system
2. Build quote in configurator
3. Email quote with portal link
4. Client reviews and accepts/rejects
5. Track status in dashboard

### Recurring Quotes
1. Clone previous quote
2. Adjust pricing/packages
3. Resend to client
4. Update when accepted

## Technical Details

### [[database-schema]]
- Users (admin accounts)
- Clients (customers)
- Quotes (quote records)
- LineItems (quote components)
- Templates (reusable packages)

### [[api-routes]]
- `/api/quotes` — Quote CRUD
- `/api/clients` — Client management
- `/api/email` — Email sending
- `/api/templates` — Template management

### [[authentication]]
NextAuth v5 with:
- Credentials provider
- Session management
- Protected routes
- Role-based access

## Development

### Setup
```bash
npm install
npm run db:push
npm run db:seed
npm run dev
```

### Environment Variables
```env
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=
EMAIL_SERVER=
```

## Deployment

- Platform: Vercel (recommended)
- Database: Neon PostgreSQL
- Email: SendGrid/Resend

## Code Location

- Repo: `13Guinness/fuel-vm-configurator`
- Local: `~/.openclaw/workspace/fuel-vm-configurator/`

## Related

- [[wp-engine-dashboard]] — Another Fuel VM admin tool
- [[quote-management]] — Business quote workflows
- [[saas-patterns]] — Multi-tenant architecture

---

**Topics:**
- [[nextjs]]
- [[quote-management]]
- [[saas]]
- [[prisma]]
