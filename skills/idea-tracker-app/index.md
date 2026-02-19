---
description: Passive Income Idea Tracker — Collaborative web app for tracking, ranking, and researching passive income product ideas. Weighted scoring, market gap tracking, AI research prompts. Next.js 14 + Prisma + NextAuth.
kind: skill-graph
topics: ["[[nextjs]]", "[[product-management]]", "[[saas]]"]
---

# Passive Income Idea Tracker

Collaborative web app for tracking and ranking passive income ideas.

## Purpose

**Problem:** Tracking startup/product ideas in:
- Scattered notes
- No prioritization system
- Hard to collaborate
- No structured research

**Solution:** Centralized tracker with:
- Weighted scoring system
- Market gap analysis
- AI research prompts
- Team collaboration

## Features

### Idea Management
- Add new ideas with description
- Edit/update ideas
- Archive completed/rejected
- Tag and categorize

### Weighted Scoring System

Rank ideas by 3 factors:
1. **Passive Income Potential** (1-10)
   - How hands-off after launch?
   - Recurring revenue vs. one-time?
   
2. **Feasibility** (1-10)
   - Can you actually build it?
   - Required skills/resources
   
3. **Revenue Potential** (1-10)
   - Market size
   - Willingness to pay
   - Competition level

**Total Score:** Sum of 3 factors (max 30)

### Market Gap Tracking

Competition level:
- **Wide Open** — Blue ocean, little competition
- **Emerging** — Growing market, early movers
- **Competitive** — Established players, needs differentiation
- **Saturated** — Crowded, hard to enter

### AI Research Prompts

Generate Claude/ChatGPT prompts for:
- Market research
- Competitor analysis
- MVP feature list
- Go-to-market strategy

**Example:**
> "Analyze the market for [idea]. What are the top 3 competitors? What gaps exist? How could we differentiate?"

### Real-Time Filtering

Filter ideas by:
- Score threshold (>20)
- Market gap (wide open only)
- Status (active/archived)
- Date added
- Tag

Sort by:
- Total score (highest first)
- Individual factor scores
- Date added
- Alphabetical

## Architecture

### Tech Stack
- **Frontend:** Next.js 14 (App Router)
- **Database:** Prisma + Vercel Postgres
- **Auth:** NextAuth.js v5
- **UI:** Tailwind CSS + shadcn/ui

### Database Schema
```
User (team members)
  ↓
Idea (product ideas)
  ├── title, description
  ├── passiveScore, feasibilityScore, revenueScore
  ├── marketGap
  ├── status
  ├── tags
  └── createdBy (User)
```

### Pages
- `/` — Login page
- `/dashboard` — Idea list + filters
- `/ideas/new` — Add idea form
- `/ideas/:id` — Edit idea
- `/api/*` — REST endpoints

## Use Cases

### Weekly Idea Review
1. Team adds ideas during week
2. Friday meeting: review dashboard
3. Sort by total score
4. Pick top 3 for research
5. Generate AI prompts
6. Assign research tasks

### Market Gap Analysis
1. Filter by "Wide Open" market gap
2. Sort by revenue potential
3. Pick ideas with least competition
4. Run AI research prompts
5. Validate assumptions

### Quarterly Planning
1. Review all active ideas
2. Archive low-scoring ideas
3. Focus on top 10
4. Build MVPs for top 3
5. Track in separate project board

## Deployment

### Vercel (Recommended)
1. Push to GitHub
2. Import to Vercel
3. Add Postgres database
4. Set environment variables
5. Deploy

### Environment Variables
```env
DATABASE_URL=           # Vercel Postgres
NEXTAUTH_SECRET=        # Random 32-char string
NEXTAUTH_URL=          # https://your-app.vercel.app
```

## Security

- NextAuth authentication
- Bcrypt password hashing
- Protected API routes
- CSRF protection
- SQL injection prevention (Prisma)

## Performance

- Server-side rendering
- Optimistic UI updates
- Prisma query optimization
- Vercel Edge caching

## Future Enhancements

**Potential features:**
- AI-powered idea validation
- Automated competitor research
- Revenue projection calculator
- Integration with project management tools
- Export to spreadsheet
- Mobile app

## Code Location

- Repo: `13Guinness/idea-tracker-app`
- Local: `~/.openclaw/workspace/idea-tracker-app/`

## Related

- [[fuel-vm-configurator]] — Similar Next.js + Prisma architecture
- [[product-management]] — Product workflows
- [[startup-tools]] — Entrepreneurial tooling

---

**Topics:**
- [[nextjs]]
- [[product-management]]
- [[saas]]
- [[idea-validation]]
