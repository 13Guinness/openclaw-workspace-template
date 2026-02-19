---
description: AI rewrite levels — control how much variation Claude AI introduces when generating or transforming location content. Low (10-20%), Medium (40-60% recommended), High (80-90%). Higher levels = more unique content but slower and more expensive.
kind: concept
topics: ["[[wp-geo-toolkit]]", "[[ai-content]]", "[[geographic-transformation]]"]
---

# AI Rewrite Levels

Control how much variation the AI introduces when generating content.

## The Three Levels

### Low (10-20% variation)

**What changes:**
- Geographic references (city, state, county)
- Location-specific landmarks
- Minimal content rewording

**What stays:**
- Original sentence structure
- Most phrasing unchanged
- Template-like consistency

**Example:**

**Original:**
> "Our Indianapolis office serves Hamilton County residents with expert HVAC services. We've been serving central Indiana since 2005."

**Low rewrite (Naples):**
> "Our Naples office serves Collier County residents with expert HVAC services. We've been serving Southwest Florida since 2005."

**Use when:**
- Template content is acceptable
- Testing the system first time
- Low risk of duplicate content
- Fast processing needed

**Pros:**
- Fast (~30-45 seconds/page)
- Predictable output
- Low API cost

**Cons:**
- Templated feel
- Less SEO value
- May trigger duplicate filters

---

### Medium (40-60% variation) **[RECOMMENDED]**

**What changes:**
- Geographic references (comprehensive)
- Sentence structure variations
- Synonym substitution
- Paragraph reordering
- Natural language flow

**What stays:**
- Core message and meaning
- Key services and offerings
- Overall structure (headings, sections)

**Example:**

**Original:**
> "Our Indianapolis office serves Hamilton County residents with expert HVAC services. We've been serving central Indiana since 2005."

**Medium rewrite (Naples):**
> "Since 2005, our Naples team has provided Southwest Florida homeowners with professional heating and cooling solutions. We're proud to serve Collier County families with reliable HVAC expertise."

**Use when:**
- Production content
- SEO matters
- Quality is priority
- Natural reading is important

**Pros:**
- Natural, human-quality writing
- Good SEO value (unique content)
- Maintains meaning while varying expression
- Best cost/quality balance

**Cons:**
- Slower (~60-90 seconds/page)
- Moderate API cost
- May occasionally need review

---

### High (80-90% variation)

**What changes:**
- Extensive rewriting
- Creative expression
- New examples and analogies
- Different narrative approaches
- Maximum uniqueness

**What stays:**
- Core business message
- Service offerings
- Contact information
- Legal disclaimers

**Example:**

**Original:**
> "Our Indianapolis office serves Hamilton County residents with expert HVAC services. We've been serving central Indiana since 2005."

**High rewrite (Naples):**
> "For nearly two decades, Southwest Florida homeowners have trusted our Naples-based HVAC specialists to keep their homes comfortable year-round. From routine maintenance to emergency repairs, we understand the unique climate challenges Collier County residents face and deliver solutions that last."

**Use when:**
- High duplicate content risk
- Competitive markets
- Premium quality needed
- Brand voice flexibility OK

**Pros:**
- Maximum uniqueness
- Excellent SEO value
- Engaging, varied content
- Best for competitive niches

**Cons:**
- Slower (~90-120 seconds/page)
- Higher API cost (~2× medium)
- More review needed
- May drift from brand voice

## How It Works Technically

### Prompt Engineering

The AI receives instructions like:

**Low:**
```
Replace geographic references but keep the structure and phrasing nearly identical. 
Aim for 10-20% content variation.
```

**Medium:**
```
Rewrite naturally while maintaining the core message. Vary sentence structure, 
use synonyms, and reorganize paragraphs. Aim for 40-60% variation. Keep it 
readable and human-quality.
```

**High:**
```
Extensively rewrite while preserving the business message. Use creative expression,
new examples, and varied narrative approaches. Aim for 80-90% variation while 
maintaining professionalism and accuracy.
```

### AI Behavior

Claude Sonnet 4 interprets these instructions and:
- Analyzes variation percentage
- Adjusts creativity temperature
- Balances structure preservation vs. innovation
- Maintains meaning while varying expression

## Choosing the Right Level

### Decision Matrix

| Scenario | Recommended Level |
|----------|------------------|
| First-time testing | Low |
| Template marketing pages | Low-Medium |
| Production service pages | Medium |
| Blog posts | Medium-High |
| High-competition niche | High |
| Brand voice critical | Medium |
| Budget-conscious | Low |
| Quality-focused | Medium-High |

### A/B Testing

Run small tests to find your optimal level:

1. Generate 10 pages at each level
2. Review output quality
3. Check Google indexing (1-2 weeks)
4. Measure organic traffic (30 days)
5. Choose level with best results

### Hybrid Approach

Use different levels for different page types:

- **Service pages:** Medium (conversions matter)
- **Location pages:** Medium (SEO + UX balance)
- **Blog posts:** High (maximum uniqueness)
- **FAQ pages:** Low (consistency OK)

## Cost Impact

Based on ~4000 tokens per page with Claude Sonnet 4:

| Level | Time/Page | Cost/Page | 100 Pages |
|-------|-----------|-----------|-----------|
| Low | 30-45s | $0.010 | ~$1.00 |
| Medium | 60-90s | $0.015 | ~$1.50 |
| High | 90-120s | $0.030 | ~$3.00 |

**Note:** Higher levels use more output tokens due to variation.

## Quality Assurance

### Review Checklist

After generation, check:

**Low level:**
- ✓ Geographic swaps correct
- ✓ No broken references
- ✓ Structural consistency

**Medium level:**
- ✓ Natural language flow
- ✓ Accurate location details
- ✓ Brand voice maintained
- ✓ No factual errors

**High level:**
- ✓ All medium checks
- ✓ Creative consistency
- ✓ No inappropriate content
- ✓ Message integrity preserved

### Common Issues

**Low level:**
- Templated feel → Consider medium
- Duplicate warnings → Increase level

**Medium level:**
- Occasional factual errors → Review before publish
- Slight brand voice drift → Update prompt

**High level:**
- Significant brand voice drift → Provide examples
- Over-creativity → Lower to medium
- Slower processing → Batch overnight

## Configuring in UI

Both add-ons offer dropdown selection:

**Location Pages Generator:**
```
WP Admin → Geo Toolkit → Location Pages
└── AI Rewrite Level: [Low | Medium | High]
```

**Content Transformer:**
```
WP Admin → Geo Toolkit → Content Transformer
└── Transformation Level: [Low | Medium | High]
```

## Technical Implementation

```php
// In prompt generation
$variation_instruction = match($rewrite_level) {
    'low' => 'Replace geographic references but keep structure identical. 10-20% variation.',
    'medium' => 'Rewrite naturally with varied structure. 40-60% variation. Maintain quality.',
    'high' => 'Extensively rewrite with creative expression. 80-90% variation.',
};

$prompt .= "\n\nVariation level: {$variation_instruction}";
```

## Code Location

- Prompt building: `WPGT_LP_Content_Generator`, `WPGT_CT_Transformer`
- UI settings: `wpgt-location-pages/admin/`, `wpgt-content-transformer/admin/`
- GitHub: Both add-on repos

## Related

- [[geographic-transformation]] — What's being transformed
- [[claude-ai-integration]] — AI service that applies the level
- [[location-pages-generator]] — Uses levels for new pages
- [[content-transformer]] — Uses levels for existing pages

---

**Topics:**
- [[wp-geo-toolkit]]
- [[ai-content]]
- [[geographic-transformation]]
- [[prompt-engineering]]
