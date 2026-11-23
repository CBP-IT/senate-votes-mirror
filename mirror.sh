#!/usr/bin/env bash
# Senate vote mirror: copies senate.gov's public roll-call vote files into this repo, at the
# same paths senate.gov uses, so the Capitol SITREP server (which senate.gov turns away) can
# read them from GitHub instead. Runs on GitHub Actions every 10 minutes.
#
# Polite by design: it reads the vote list for the current Congress (2 small files), then
# fetches only votes it doesn't have yet, one at a time, 2 seconds apart, at most MAX per run.
set -uo pipefail
MAX=${MAX:-150}
GAP=${GAP:-2}
UA="CapitolSITREP-mirror/1.0 (+https://capitolsitrep.com/about)"
BASE=${BASE:-https://www.senate.gov/legislative/LIS}

year=$(date -u +%Y)
congress=${CONGRESS:-$(( (year - 1789) / 2 + 1 ))}
first_year=$(( 1789 + (congress - 1) * 2 ))
sessions="1"; [ "$year" -gt "$first_year" ] && sessions="1 2"

get() { # url, out-file. Writes only a real XML answer; returns non-zero otherwise.
  local tmp; tmp=$(mktemp)
  local code; code=$(curl -s --max-time 30 -A "$UA" -o "$tmp" -w '%{http_code}' "$1")
  sleep "$GAP"
  if [ "$code" = 200 ] && grep -q "$3" "$tmp"; then mkdir -p "$(dirname "$2")"; mv "$tmp" "$2"; return 0; fi
  rm -f "$tmp"; echo "  $code for ${1#$BASE/}"; return 1
}

fetched=0
for s in $sessions; do
  menu="legislative/LIS/roll_call_lists/vote_menu_${congress}_${s}.xml"
  if ! get "$BASE/roll_call_lists/vote_menu_${congress}_${s}.xml" "$menu.new" "<vote_summary"; then
    echo "No vote list yet for the ${congress}th Congress, session $s."; continue
  fi
  latest=$(grep -o '<vote_number>[0-9]*' "$menu.new" | grep -o '[0-9]*$' | sort -n | tail -1)
  latest=$((10#${latest:-0}))
  echo "Congress $congress session $s: senate.gov lists $latest vote(s)."
  dir="legislative/LIS/roll_call_votes/vote${congress}${s}"
  for n in $(seq 1 "$latest"); do
    f="$dir/vote_${congress}_${s}_$(printf %05d "$n").xml"
    [ -s "$f" ] && continue
    [ "$fetched" -ge "$MAX" ] && break
    get "$BASE/roll_call_votes/vote${congress}${s}/$(basename "$f")" "$f" "<roll_call_vote" && fetched=$((fetched + 1))
  done
  # Re-read the newest vote each run: senate.gov sometimes corrects a file soon after a vote.
  if [ "$latest" -gt 0 ]; then
    f="$dir/vote_${congress}_${s}_$(printf %05d "$latest").xml"
    get "$BASE/roll_call_votes/vote${congress}${s}/$(basename "$f")" "$f" "<roll_call_vote" || true
  fi
  mv "$menu.new" "$menu"
done
echo "Fetched $fetched new vote file(s)."
date -u +%FT%TZ > last-checked.txt
