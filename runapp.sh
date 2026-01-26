#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: runapp <project-name> [-p|--port PORT] [-k|--kill]" >&2
  echo "  -p, --port PORT    Specify port number (optional)" >&2
  echo "  -k, --kill         Kill the tmux session for this project" >&2
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

project_name="$1"
port=""
kill_session=false
shift

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

base_dir="$HOME/projects"
app_dir="$base_dir/$project_name"
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
  env_port=$(grep -E '^APP_PORT=' "$env_file" | cut -d'=' -f2 | tr -d '[:space:]"' || true)
  if [[ -n "$env_port" ]]; then
    port="$env_port"
    echo "Using APP_PORT from .env: $port"
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

php artisan serve --port=__PORT__
EOF
)

main_cmd="${main_cmd/__PORT__/$port}"

echo "Runapp V 1.2"
# echo "Laravel running at http://127.0.0.1:${port}"

# Start a new tmux session
tmux new-session -s "$session" -c "$app_dir" "bash -lc '$main_cmd'"

# Wait 3 seconds before creating the next window
sleep 3

# Create a second window and run npm dev
tmux new-window -t "$session" -n "dev" -c "$app_dir"
tmux send-keys -t "$session:dev" "npm run dev" C-m

# Select the first window before attaching
tmux select-window -t "$session:0"

# Attach to the session so VS Code can see output
tmux attach -t "$session"