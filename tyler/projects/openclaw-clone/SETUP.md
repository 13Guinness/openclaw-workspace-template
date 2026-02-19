# OpenClaw Setup Guide

## Quick Start

1. **Install Homebrew:**
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

2. **Install Node.js and GitHub CLI:**
   ```
   brew install node gh
   gh auth login
   ```

3. **Get API Keys:**
   - Anthropic: console.anthropic.com
   - OpenRouter: openrouter.ai/keys
   - OpenAI: platform.openai.com
   - Telegram: @BotFather

4. **Run Setup:**
   ```
   cd ~/.openclaw/workspace/tyler/projects/openclaw-clone
   ./setup.sh
   ```

5. **Run Post-Setup:**
   ```
   ./post-setup.sh
   ```

Your agent is **Tyler** (Tyler Durden personality). Edit USER.md to fill in your details.
