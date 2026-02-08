# --- ssh interactive wrapper: picks Hosts from ~/.ssh/config ---

# Recursively collect SSH config files, following simple Include directives.
# Note: Supports common patterns like: Include ~/.ssh/conf.d/*.conf
__ssh_config_files() {
  local start="${1:-$HOME/.ssh/config}"
  local -a queue
  local -A seen
  local f

  queue=("$start")

  while ((${#queue[@]})); do
    f="${queue[0]}"
    queue=("${queue[@]:1}")

    [[ -z "$f" ]] && continue
    [[ -e "$f" ]] || continue

    # Normalize key
    local key="$f"
    [[ -n "${seen[$key]+x}" ]] && continue
    seen["$key"]=1

    printf '%s\n' "$f"

    # Find Include directives in this file and enqueue expanded paths
    # Handles: Include path/glob
    # Multiple includes per line supported.
    while IFS= read -r line; do
      # Strip comments
      line="${line%%#*}"
      [[ "$line" =~ ^[[:space:]]*[Ii]nclude[[:space:]]+(.+) ]] || continue

      local rest="${BASH_REMATCH[1]}"
      # Split rest into words (ssh_config allows multiple patterns)
      local pat
      for pat in $rest; do
        # Expand ~
        pat="${pat/#\~/$HOME}"
        # Expand globs
        local match
        shopt -s nullglob
        for match in $pat; do
          queue+=("$match")
        done
        shopt -u nullglob
      done
    done < "$f"
  done
}

# Extract Host entries (names) from the config(s)
__ssh_list_hosts() {
  local -a files
  mapfile -t files < <(__ssh_config_files "$HOME/.ssh/config")

  # Parse Host lines; ignore wildcard patterns like '*' '?' and negations '!foo'
  # Also ignores "Host *" etc.
  awk '
    BEGIN { IGNORECASE=1 }
    {
      sub(/#.*/, "", $0)               # strip comments
      if ($1 ~ /^[Hh][Oo][Ss][Tt]$/) {
        for (i=2; i<=NF; i++) {
          h=$i
          if (h ~ /^[!*]/) continue    # negations and wildcard-only
          if (h ~ /[*?]/) continue     # skip patterns
          print h
        }
      }
    }
  ' "${files[@]}" 2>/dev/null | sort -u
}

ssh() {
  # Pass-through if:
  # - Not interactive shell
  # - Any args provided (you typed ssh host / ssh -p ... / etc.)
  if [[ $- != *i* ]] || [[ $# -gt 0 ]]; then
    command ssh "$@"
    return $?
  fi

  local -a hosts
  mapfile -t hosts < <(__ssh_list_hosts)

  if ((${#hosts[@]} == 0)); then
    echo "No SSH Host entries found in ~/.ssh/config" >&2
    return 1
  fi

  local choice

  # If fzf exists, arrow-key picker + preview
  if command -v fzf >/dev/null 2>&1; then
    choice="$(
      printf "%s\n" "${hosts[@]}" |
        fzf --prompt="ssh > " --no-multi --height=40% --border \
            --preview 'command ssh -G {} 2>/dev/null | egrep "^(hostname|user|port|identityfile|proxyjump|forwardagent|serveraliveinterval) " | sed "s/^/  /"'
    )"
    [[ -z "$choice" ]] && return 130
    command ssh "$choice"
    return $?
  fi

  # Fallback: numbered menu
  echo
  echo "SSH Hosts from ~/.ssh/config:"
  local i=1
  for h in "${hosts[@]}"; do
    printf "  %2d) %s\n" "$i" "$h"
    ((i++))
  done
  echo

  while true; do
    read -r -p "Choose (number/name, blank=cancel): " choice
    [[ -z "$choice" ]] && return 130

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      local idx=$((choice-1))
      if (( idx >= 0 && idx < ${#hosts[@]} )); then
        command ssh "${hosts[$idx]}"
        return $?
      fi
      echo "Invalid number."
      continue
    fi

    # exact match?
    local found=""
    for h in "${hosts[@]}"; do
      [[ "$h" == "$choice" ]] && found="$h" && break
    done
    if [[ -n "$found" ]]; then
      command ssh "$found"
      return $?
    fi

    # unique partial match?
    local match="" count=0
    for h in "${hosts[@]}"; do
      if [[ "$h" == *"$choice"* ]]; then
        match="$h"; ((count++))
      fi
    done
    if (( count == 1 )); then
      command ssh "$match"
      return $?
    elif (( count > 1 )); then
      echo "Ambiguous: multiple matches."
    else
      echo "No match."
    fi
  done
}

# --- end ssh wrapper ---
