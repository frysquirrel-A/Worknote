---
name: ui-review-operator
description: Safe WorkNote emulator and screenshot review workflow. Use when the user asks to inspect screens, press emulator buttons, capture PNG/XML files, generate HTML review reports, summarize each screen's features, or connect UI findings back to AGENTS.md, PROJECT_MAP.md, ARCHITECTURE.md, PATCHLOG.md, and AI_CHECKLIST.md.
---

# UI Review Operator

## Purpose
Explore WorkNote's internal UI safely, capture evidence, and produce a review artifact that a human or another AI can use for design or UX decisions.

## Read First
Read these files before exploration if present:
- `AGENTS.md`
- `PROJECT_MAP.md`
- `ARCHITECTURE.md`
- `PATCHLOG.md`
- `AI_CHECKLIST.md`

## Workflow
1. Clean the previous screenshot session if the user asked for a fresh run.
2. Use the currently running emulator if available.
3. Capture each meaningful screen with:
   - PNG screenshot
   - UI hierarchy XML dump
4. Keep a session manifest and notes file.
5. Group captures by app area:
   - Home
   - Tasks
   - Schedule
   - Journal
   - Gallery
   - Messenger
   - External/Auth
   - Error/ANR
   - Unknown
6. Generate `review.html` with:
   - step summary
   - feature summary
   - design concept summary
   - linked source documents
   - raw PNG/XML links

## Safe Exploration Rules
- Prefer internal, non-destructive UI only.
- Do not enter:
  - Google sign-in
  - account picker
  - Chrome/browser/webview auth
  - logout
  - reset/delete flows
  - payment flows
- If external auth appears:
  - capture it
  - classify it as `External/Auth`
  - stop that branch
- If the screen repeats or the app becomes blank, ANR, or splash-looped:
  - capture it
  - record the issue
  - stop that branch

## Review Expectations
For each screen, record:
- what action led to the screen
- what features are visible
- what design or information architecture concept is implied
- which project documents define or constrain that concept
- what looks wrong, weak, inconsistent, or risky

## Forbidden Actions
- Do not invent hidden features from screenshots.
- Do not claim a control works unless the captured transition proves it.
- Do not open destructive or external flows to finish the inspection.
- Do not silently overwrite an existing session if the user asked to preserve it.

## Stop Conditions
Stop and report if:
- the emulator is not available
- ADB cannot capture screenshots or XML
- the app cannot reach internal UI safely
- external auth blocks further safe exploration

## Final Report Format
- session folder path
- explored areas
- blocked/avoided flows
- key UX findings
- generated files:
  - `review.html`
  - `notes.txt`
  - `review_data.json`
  - `session_manifest.json`
