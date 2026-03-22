# CLI Intro: Current State And Direction

## Current test result
- Audio output is still not working.
- Shake control / motion gesture behavior is still not working.

## Allowed investigation sources
- Use the forked GitHub branches that contain the original Lineage-based code for comparison.
- Use the old Android 15 maintainer repos here:
  - `https://github.com/jef00?tab=repositories`
- Use the OnePlus 8T PixelOS 16.2 org repos as reference for the sister device:
  - `https://github.com/orgs/PixelOS-OnePlus-8T-Kebab/repositories`

## Project direction
- The immediate goal is to finish a stable and working PixelOS 16.1 bring-up for `instantnoodlep`.
- After 16.1 is stable, the plan is to move toward 16.2.
- Any fixes added now should prefer approaches that also make sense for that later 16.2 upgrade path.

## What to do next
- fix the remaining runtime issues.
- Prioritize root-causing:
  - speaker/audio output
  - shake control / missing motion sensor behavior
- When useful, compare against:
  - original/forked Lineage branches
  - the Android 15 maintainer trees
  - the bootable 8T PixelOS 16.2 trees
- Prefer fixes that are clean, upstreamable, and compatible with the future 16.2 migration.