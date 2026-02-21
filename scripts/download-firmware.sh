#!/usr/bin/env bash
set -euo pipefail

# Download the latest firmware build from GitHub Actions.

# --- Colors (disabled if not a terminal) ---

if [[ -t 1 ]]; then
  RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' BOLD=$'\033[1m' RESET=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

warn()  { echo "${YELLOW}Warning:${RESET} $*"; }
error() { echo "${RED}Error:${RESET} $*" >&2; }
info()  { echo "${CYAN}${BOLD}==>${RESET} $*"; }
ok()    { echo "${GREEN}${BOLD}==>${RESET} $*"; }

# --- Preflight ---

if ! command -v gh &>/dev/null; then
  error "gh CLI is not installed. Install it from https://cli.github.com"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  error "not inside a git repository."
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
branch="$(git rev-parse --abbrev-ref HEAD)"

# --- Unpushed commit warning ---

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [[ -n "$upstream" ]]; then
  local_head="$(git rev-parse HEAD)"
  remote_head="$(git rev-parse "$upstream" 2>/dev/null || true)"
  if [[ "$local_head" != "$remote_head" ]]; then
    warn "local HEAD ($local_head) differs from $upstream ($remote_head)."
    echo "         You may have unpushed commits — the latest CI build may not match your local code."
    echo
  fi
else
  warn "no upstream tracking branch for '$branch'. Cannot check for unpushed commits."
  echo
fi

# --- Find latest run ---

info "Looking for the latest workflow run on branch '$branch'..."

run_info="$(gh run list --branch "$branch" --limit 1 --json databaseId,status,conclusion,headSha,url \
  --jq '.[0] | [.databaseId, .status, .conclusion, .headSha, .url] | @tsv')"

if [[ -z "$run_info" ]]; then
  error "no workflow runs found for branch '$branch'."
  exit 1
fi

read -r run_id status conclusion head_sha run_url <<<"$run_info"

echo "Run #${run_id}: status=$status conclusion=$conclusion"
echo "  SHA: $head_sha"
echo "  URL: $run_url"
echo

# --- Wait for in-progress runs ---

while [[ "$status" != "completed" ]]; do
  warn "run is still in progress, waiting 15s..."
  sleep 15
  run_info="$(gh run view "$run_id" --json status,conclusion --jq '[.status, .conclusion] | @tsv')"
  read -r status conclusion <<<"$run_info"
done

# --- Check conclusion ---

if [[ "$conclusion" != "success" ]]; then
  error "run finished with conclusion '$conclusion'."
  echo "  See: $run_url" >&2
  exit 1
fi

# --- Download ---

short_sha="${head_sha:0:7}"
dest_dir="$repo_root/firmware/firmware-${short_sha}"

if [[ -d "$dest_dir" ]]; then
  ok "Firmware already downloaded at $dest_dir — skipping download."
else
  info "Downloading firmware to $dest_dir..."
  gh run download "$run_id" -n firmware.zip -D "$dest_dir"
  ok "Download complete."
fi

echo
ok "Firmware files:"
ls -1 "$dest_dir"/*.uf2 2>/dev/null || ls -1 "$dest_dir"
echo
echo "To flash: put each half into bootloader mode (double-tap reset) and copy the matching .uf2 file to the USB drive."
