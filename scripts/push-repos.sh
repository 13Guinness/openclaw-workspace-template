pairs="cache-warmer:cache-warmer
fvm-ai-editor-assistant:fvm-ai-editor-assistant
fvm-ai-meta-assistant:fvm-ai-meta-assistant
local-seo-autopilot-v2.0.0:local-seo-autopilot
dashboard/claude-api-dashboard:claude-api-dashboard
WP Geo Toolkit/wp-geo-toolkit:wp-geo-toolkit
WP Geo Toolkit/wpgt-content-transformer:wpgt-content-transformer
WP Geo Toolkit/wpgt-location-pages:wpgt-location-pages
wayback-restorer:wayback-restorer"

echo "$pairs" | while IFS=: read -r path name; do
  echo "=== $name ==="
  cd ~/Local\ Sites/"$path" 2>/dev/null || { echo "SKIP: not found"; echo ""; continue; }
  git init 2>/dev/null
  git add -A 2>/dev/null
  git commit -m "Initial commit" 2>/dev/null
  ~/bin/gh repo create "13Guinness/$name" --private --source=. --push 2>&1
  echo ""
done
echo "Done"
