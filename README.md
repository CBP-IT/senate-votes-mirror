# Senate vote mirror

A public copy of the U.S. Senate's roll-call vote files from
[senate.gov](https://www.senate.gov/general/XML.htm), kept at the same paths senate.gov uses
(`legislative/LIS/roll_call_votes/...` and `legislative/LIS/roll_call_lists/...`).

A GitHub Actions job (`.github/workflows/mirror.yml`) runs `mirror.sh` every 10 minutes. It
reads the current Congress's vote lists, fetches only votes it doesn't have yet, one file every
2 seconds, and commits them. The files are the Senate's public record, unchanged.

**Why it exists:** senate.gov turns away requests from Capitol SITREP's server (in Europe) and
from Cloudflare, but answers GitHub. The server reads these files from
`https://raw.githubusercontent.com/CBP-IT/senate-votes-mirror/main/` instead (setting
`SENATE_MIRROR_URL`). The source lives in the Capitol SITREP repo under `infra/senate-mirror/`.

- **Run it now:** Actions tab → Mirror Senate votes → Run workflow.
- **Pause it:** Actions tab → Mirror Senate votes → ⋯ → Disable workflow.
- **How fresh is it:** `last-checked.txt` holds the time of the last check (committed when new
  votes arrive). GitHub's timer often runs 5 to 20 minutes late.
