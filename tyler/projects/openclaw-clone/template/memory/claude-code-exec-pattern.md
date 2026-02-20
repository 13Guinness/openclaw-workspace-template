# Claude Code Exec Pattern

When using Claude Code via exec tool:
- Always use pty:true for interactive CLIs
- Use background:true for long-running tasks
- Monitor with process(action=log)
- Always have a git repo initialized in workdir
