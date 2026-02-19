---
description: Geographic transformation — the process of rewriting content to reference a different location while maintaining natural, human-quality language. AI handles contextual nuances that find-replace and content spinners cannot.
kind: concept
topics: ["[[wp-geo-toolkit]]", "[[ai-content]]"]
---

# Geographic Transformation

Rewriting content to reference a different location while maintaining natural language.

## The Problem

### Find-Replace Fails

**Input:**
> "Our Indianapolis office serves Hamilton County residents with 15 years of experience."

**Find-replace output:**
> "Our Naples office serves Collier County residents with 15 years of experience."

**Issues:**
- Templated, robotic language
- Obvious pattern to search engines
- No contextual understanding
- Misses indirect references

### Content Spinners Fail

**Spinner output:**
> "Our Naples establishment provides services to Collier County inhabitants with one and a half decades of expertise."

**Issues:**
- Unreadable gibberish
- Keyword stuffing
- User experience disaster
- Search engines penalize

## The AI Solution

**AI transformation output:**
> "Our Naples team has been serving Southwest Florida families since 2008, with deep roots in the Collier County community."

**Why better:**
- Natural, human-quality language
- Contextual understanding (Southwest Florida)
- Maintains meaning while varying expression
- SEO-safe (unique content)

## How AI Handles Nuance

### 1. Geographic Context

**Before:**
> "Located in central Indiana near I-465..."

**After:**
> "Located in Southwest Florida near I-75..."

AI knows:
- Indianapolis → central Indiana
- Naples → Southwest Florida
- I-465 → I-75

### 2. Regional Language

**Before:**
> "Whether you're from Broad Ripple or Carmel..."

**After:**
> "Whether you're from Old Naples or Park Shore..."

AI maps:
- Neighborhoods (Broad Ripple → Old Naples)
- Suburbs (Carmel → Park Shore)
- Regional references

### 3. Climate & Seasonal References

**Before:**
> "Winter snow removal available December-March"

**After:**
> "Hurricane preparedness services June-November"

AI adapts:
- Seasonal services
- Climate considerations
- Regional events

### 4. Demographic & Cultural Context

**Before:**
> "Serving Indiana families for over 20 years"

**After:**
> "Serving Southwest Florida retirees and families for over 20 years"

AI understands:
- Target demographics (retirees in Florida)
- Cultural context
- Economic factors

## AI Rewrite Levels

Via [[ai-rewrite-levels]], control how much the AI transforms:

### Low (10-20% variation)
- Geographic swaps only
- Minimal content changes
- Fast, predictable

**Use when:**
- Template content
- Testing the system
- Low duplicate risk

### Medium (40-60% variation)
- Balanced transformation
- Natural language rewriting
- Recommended default

**Use when:**
- Production content
- SEO matters
- Quality is priority

### High (80-90% variation)
- Extensive rewriting
- Maximum uniqueness
- Slower, more expensive

**Use when:**
- High duplicate risk
- Competitive markets
- Premium quality needed

## SEO Benefits

### Unique Content
- No duplicate content penalties
- Each page is truly unique
- Natural language variation

### Local Keywords
- AI naturally injects local terms
- County names, neighborhoods
- Regional landmarks

### User Intent
- Reads naturally to humans
- Better engagement metrics
- Lower bounce rates

## Technical Implementation

### Prompt Engineering

The AI prompt includes:
- Source location(s)
- Target location(s)
- Rewrite level
- Structure preservation rules
- SEO requirements

### Structure Preservation

AI maintains:
- Gutenberg blocks
- HTML tags
- Heading hierarchy
- List formatting
- Link structure

### Content Protection

Certain elements never transform:
- Business names (unless specified)
- Contact information
- Prices and offers
- Schema markup (handled separately)

## Use Cases

### [[location-pages-generator]]
Creates new pages with unique content for each location:
- Template page → 50 location variations
- All unique, all natural
- SEO-optimized from day one

### [[content-transformer]]
Updates existing pages in-place:
- Business relocation (IN → FL)
- Market expansion (1 state → 5 states)
- Generic → localized

## Quality Assurance

### Human Review
Always review AI output before publishing:
- Factual accuracy
- Brand voice consistency
- Inappropriate content

### Automated Checks
System validates:
- Location data injected correctly
- Word count maintained (~80-120%)
- Structure preserved
- Links still valid

## Limitations

### What AI Can't Do

**Complete factual rewrites:**
- Can't invent new services
- Can't fabricate credentials
- Requires source truth

**Perfect local knowledge:**
- May miss hyper-local references
- Occasional geographic errors
- Review needed for accuracy

**Brand voice replication:**
- May not match exact tone
- Needs style guidelines in prompt
- Best with clear examples

## Cost-Benefit Analysis

**Traditional (100 pages):**
- 200 hours of writing
- $10,000+ in costs
- Weeks/months to complete

**AI Transformation (100 pages):**
- 2 hours of processing
- $1.50 in API costs
- Complete in hours

**ROI:** 99% cost reduction, 100× faster

## Code Location

Core transformation logic:
- `WPGT_LP_Content_Generator` (Location Pages)
- `WPGT_CT_Transformer` (Content Transformer)
- Uses [[claude-ai-integration]]

## Related

- [[ai-rewrite-levels]] — Control variation amount
- [[claude-ai-integration]] — AI service powering transformation
- [[location-pages-generator]] — Creates new transformed pages
- [[content-transformer]] — Updates existing pages

---

**Topics:**
- [[wp-geo-toolkit]]
- [[ai-content]]
- [[local-seo]]
- [[prompt-engineering]]
