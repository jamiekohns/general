#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: runapp <app-dir-path> [-p|--port PORT] [-k|--kill]" >&2
  echo "  -p, --port PORT    Specify port number (optional)" >&2
  echo "  -k, --kill         Kill the tmux session for this project" >&2
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

app_dir="$1"
port=""
kill_session=false
shift

# Resolve full path (handles ~, ., .., and relative paths)
app_dir="${app_dir/#\~/$HOME}"  # Expand ~ to $HOME
app_dir="$(cd "$app_dir" 2>/dev/null && pwd)" || {
  echo "Error: Cannot resolve path: $1" >&2
  exit 1
}

# Print version info
echo "Runapp V 1.2"

# Parse optional port flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      if [[ $# -lt 2 ]]; then
        echo "Error: -p/--port requires a value" >&2
        exit 1
      fi
      port="$2"
      shift 2
      ;;
    -k|--kill)
      kill_session=true
      shift
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Derive project name from app_dir (basename of the path)
project_name="$(basename "$app_dir")"
session="$project_name"

# Handle kill session flag
if [[ "$kill_session" == true ]]; then
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux kill-session -t "$session"
    echo "tmux session '$session' killed."
  else
    echo "tmux session '$session' not found."
  fi
  exit 0
fi

if [[ ! -d "$app_dir" ]]; then
  echo "Error: project directory not found: $app_dir" >&2
  exit 1
fi

find_free_port() {
  local p=81
  while :; do
    if ! ss -ltnH | awk '{print $4}' | grep -qE "(:|\\])$p$"; then
      echo "$p"
      return 0
    fi
    p=$((p+1))
  done
}

# Check for APP_PORT in .env file (highest priority)
env_file="$app_dir/.env"
if [[ -f "$env_file" ]]; then
  app_port=$(grep -E '^APP_PORT=' "$env_file" | cut -d'=' -f2 | tr -d '[:space:]"' || true)
  if [[ -n "$app_port" ]]; then
    port="$app_port"
    echo "Using APP_PORT from .env: $port"
  fi
  vite_port=$(grep -E '^VITE_PORT=' "$env_file" | cut -d'=' -f2 | tr -d '[:space:]"' || true)
  if [[ -n "$vite_port" ]]; then
    vport="$vite_port"
    echo "Using VITE_PORT from .env: $vport"
  fi
fi

if [[ -z "${port}" ]]; then
  port="$(find_free_port)"
fi

# Build the command that runs in the first tmux window
main_cmd=$(cat <<'EOF'
if [[ ! -f .env ]]; then
  echo "WARNING: .env not found. Aborting."
  exec bash
fi

if [[ ! -d vendor ]]; then
  composer install || exec bash
fi

if [[ ! -d node_modules ]]; then
  npm install || exec bash
fi

php artisan serve --port=__PORT__ || exec bash
EOF
)

main_cmd="${main_cmd/__PORT__/$port}"

# Start tmux session) and run main command in initial window
tmux new-session -d -s "$session" -c "$app_dir" "bash -lc '$main_cmd; exec bash'"

# Create a second window and run npm dev
tmux new-window -t "$session" -n "dev" -c "$app_dir"
tmux send-keys -t "$session:dev" "npm run dev -- --port $vport" C-m

# Give the window a moment to start
sleep 0.5

# Wait until a localhost URL appears in the tmux pane, then echo it to VS Code terminal
timeout=150  # 30 seconds (150 * 0.2)
elapsed=0
url=""
while [[ $elapsed -lt $timeout ]]; do
  # Capture the pane content and search for URL (with error handling)
  if pane_content=$(tmux capture-pane -t "$session:dev" -p 2>/dev/null); then
    url=$(echo "$pane_content" | grep -Eo 'http://(localhost|127\.0\.0\.1):[0-9]+' | head -n1 || true)
    if [[ -n "$url" ]]; then
      echo "Vite running at $url"
      break
    fi
  fi
  sleep 0.2
  elapsed=$((elapsed + 1))
done

if [[ -z "$url" ]]; then
  echo "Warning: Vite URL not detected after 30 seconds"
  echo "Check tmux session: tmux attach -t $session"
fi

# Print URL in this terminal so VS Code auto-forwards it
echo "Laravel running at http://localhost:${port}"
echo "Vite running at http://localhost:${vport}"

echo "tmux session '$session' started."
echo "Attach with: tmux attach -t $session"