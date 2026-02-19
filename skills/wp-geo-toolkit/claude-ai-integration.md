---
description: Claude AI integration service — handles API calls to Anthropic Claude Sonnet 4 for content generation with retry logic, rate limit handling, and response validation
kind: core-service
topics: ["[[wp-geo-toolkit]]", "[[claude-api]]"]
---

# Claude AI Integration

Interface to Anthropic's Claude Sonnet 4 for AI content generation.

## Why Claude Sonnet 4

- **Structure preservation:** Best at maintaining Gutenberg blocks, HTML
- **Instruction following:** Excellent at complex multi-step prompts
- **Natural language:** Human-quality writing
- **Cost-effective:** $0.015/page vs GPT-4's $0.03/page

## Features

- Automatic retry with exponential backoff
- Rate limit handling
- JSON parsing with error recovery
- Response validation
- Detailed error logging

## Usage

```php
$claude = wpgt()->get_claude_api();
$response = $claude->generate($prompt, [
    'max_tokens' => 4000,
    'temperature' => 1.0
]);
```

## API Configuration

**Required:**
- Claude API key from [console.anthropic.com](https://console.anthropic.com)
- Stored in: WP Admin → Geo Toolkit → Settings

**Cost:**
- Pay-as-you-go pricing
- ~4000 tokens per location page
- ~$0.015 per page generated

## Error Handling

**Rate Limits:**
- Automatic retry with backoff (1s, 2s, 4s delays)
- Max 3 retries before failing
- User-visible progress updates

**Invalid Responses:**
- JSON parsing with error recovery
- Extracts content from partial responses
- Falls back to raw text if JSON corrupt

**Network Errors:**
- Connection timeouts handled
- Retries on transient failures
- Detailed logging for debugging

## Response Format

Claude returns JSON with:
```json
{
  "content": "Full page content...",
  "seo_title": "SEO-optimized title",
  "meta_description": "Meta description...",
  "schema": {
    "@type": "LocalBusiness",
    "name": "...",
    "address": {...}
  },
  "faq": [...]
}
```

## Code Location

- Class: `WPGT_Claude_API`
- File: `wp-geo-toolkit/includes/class-claude-api.php`
- GitHub: `13Guinness/wp-geo-toolkit`

## Related

- [[prompt-engineering]] — Building effective prompts
- [[location-pages-generator]] — Main consumer of this service
- [[content-transformer]] — Also uses Claude for rewrites

---

**Topics:**
- [[wp-geo-toolkit]]
- [[claude-api]]
- [[ai-content]]
