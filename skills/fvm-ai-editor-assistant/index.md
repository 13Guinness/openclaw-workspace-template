---
description: FVM AI Editor Assistant — Gutenberg sidebar plugin with AI-powered SEO suggestions, audio notifications, and license management. Enhanced version of Meta Assistant with multi-feature sidebar.
kind: skill-graph
topics: ["[[wordpress]]", "[[seo]]", "[[gutenberg]]", "[[claude-api]]"]
---

# FVM AI Editor Assistant

Advanced Gutenberg sidebar plugin with AI SEO suggestions, audio, and licensing.

## Purpose

**Evolution of [[fvm-ai-meta-assistant]]:**
- Started as meta tag generator
- Expanded to full SEO assistant
- Added audio notifications
- License management system

**Current:** Multi-feature sidebar for content optimization.

## Features

### AI SEO Suggestions
Beyond just meta tags:
- Content improvement suggestions
- Keyword optimization
- Readability analysis
- Internal linking recommendations
- Image alt text suggestions

### Audio Notifications
- Text-to-speech for notifications
- Progress updates
- Error alerts
- Completion confirmations

Why: Audible feedback while working in editor.

### License Management
- API key validation
- Usage tracking
- License status display
- Renewal reminders

### Meta Tag Generation
Inherited from [[fvm-ai-meta-assistant]]:
- One-click meta titles
- SEO descriptions
- SEO plugin compatibility

## Architecture

### Gutenberg Integration
```
Gutenberg Editor
  ↓
Custom Sidebar Panel
  ↓
React Components (SEO, Audio, License)
  ↓
WordPress REST API
  ↓
Claude API / TTS Service
```

### Multi-Panel Sidebar
```
FVM AI Editor Assistant
├── SEO Suggestions
├── Meta Generator
├── Audio Controls
└── License Status
```

## Key Components

### [[seo-suggestions]]
AI-powered content analysis:
- Analyzes current content
- Suggests improvements
- Identifies opportunities
- Real-time feedback

### [[audio-system]]
Text-to-speech notifications:
- Browser speech synthesis
- Custom voice selection
- Mute/unmute toggle
- Event-based triggers

### [[license-manager]]
API key and usage tracking:
- Key validation
- Usage quotas
- Status display
- Renewal flow

## Use Cases

### Content Writing Flow
1. Write draft in Gutenberg
2. Check SEO suggestions panel
3. Implement AI recommendations
4. Generate meta tags
5. Audio confirms completion
6. Publish

### Batch Content Optimization
1. Open old post
2. Run SEO suggestions
3. Apply improvements
4. Update meta tags
5. Move to next post
6. Audio confirms each step

## Settings

**WP Admin → Settings → AI Editor Assistant**

- Claude API key
- Audio settings (voice, speed, enabled)
- SEO suggestion preferences
- License information

## Version History

**Current:** v1.4.4

### Feature Evolution
- v1.0: Meta tag generation only
- v1.2: Added SEO suggestions
- v1.3: Audio notifications
- v1.4: License management

## API Integration

### Claude API
- Same patterns as [[claude-api-integration]]
- Additional endpoints for suggestions
- Higher token usage (~1000/analysis)

### Browser TTS
- Web Speech API
- No external service
- Free, instant
- Browser compatibility required

## Security

- API key encrypted
- Admin-only (`manage_options`)
- Nonce verification
- Sanitization/escaping
- OWASP compliance

## Performance

- Lightweight sidebar
- AJAX for analysis
- Non-blocking UI
- Cached suggestions (session)

## Code Location

- Repo: `13Guinness/fvm-ai-editor-assistant`
- Local: `~/.openclaw/workspace/fvm-ai-editor-assistant/`
- WordPress: `/wp-content/plugins/fvm-ai-editor-assistant/`

## Related

- [[fvm-ai-meta-assistant]] — Simpler meta-only version
- [[local-seo-autopilot]] — Full audit suite
- [[gutenberg-plugins]] — Block editor patterns
- [[claude-api-integration]] — AI integration

---

**Topics:**
- [[wordpress]]
- [[seo]]
- [[gutenberg]]
- [[claude-api]]
- [[tts]]
