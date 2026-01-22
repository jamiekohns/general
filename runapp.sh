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

# Start tmux session (detached) and run main command in initial window
tmux new-session -d -s "$session" -c "$app_dir" "bash -lc '$main_cmd'"

# Print URL in this terminal so VS Code auto-forwards it
echo "Laravel running at http://127.0.0.1:${port}"

# Create a second window to run npm dev
tmux new-window -t "$session" -n "dev" -c "$app_dir" "bash -lc 'npm run dev'"

# Pipe the dev window output to a log file
vite_log="/tmp/${session}-vite.log"
tmux pipe-pane -t "$session:dev" -o "cat >> '$vite_log'"

# Wait until a localhost URL appears, then echo it to VS Code terminal
while :; do
  if grep -Eo 'http://(localhost|127\.0\.0\.1):[0-9]+' "$vite_log" | head -n1 | read -r url; then
    echo "Vite running at $url"
    break
  fi
  sleep 0.2
done

echo "tmux session '$session' started."
echo "Attach with: tmux attach -t $session"