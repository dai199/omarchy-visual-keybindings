# Marketplace publication

Prepared on 2026-09-14 against the official
[publishing guide](https://plugins.omarchy.org/publish.html) and
[submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).

## Listing draft

- Title: `[Plugin]: Visual Keybindings`
- Repository: https://github.com/dai199/omarchy-visual-keybindings
- Plugin ID: `dai199.visual-keybindings`
- Version: `0.1.0` (early preview)
- Category: `Productivity`
- Tags: `hyprland`, `quickshell`
- Preview: root `preview.png`, matching `docs/screenshot.png`; captured from the
  installed plugin on 2026-09-15, showing Super shortcuts and Super+T details
- Issue body: [marketplace-submission.md](marketplace-submission.md)

The repository was confirmed public with default branch `master` and public
HEAD `fb33ad5acc14ff93f0a738f00f39bbf7c89ba913`. No matching ID or repository
was found in the current official registry during preparation. This is not
a reservation of the ID; submission validation remains authoritative.

## Checks before submitting

1. Review the README and screenshot. The current screenshot captures only the
   plugin panel, without the desktop background or other applications.
   Confirm permission to publish all included assets.
2. Smoke-test opening and closing, physical and clicked modifier combinations,
   and creating, editing, removing, and restoring a harmless shortcut in a
   disposable test configuration. Automated helper tests do not verify the
   live QML interface. The GitHub installation and live editing checks were
   subsequently completed; see [Installation verification](install-verification.md).
   The owner subsequently confirmed physical chord selection and modifier
   release on 2026-09-15.
3. Run `omarchy plugin validate .`,
   `python3 -m unittest discover -s tests -v`, and `git diff --check`.
   Manifest validation and all 32 helper tests passed during preparation.
4. Review and commit the publication files, then push them to the public
   default branch. Do not accidentally include the unrelated local `HANDOFF.md`.
   The helper-path fix was subsequently committed and pushed as `3d255be`.
   The README includes an animated demo, an MP4 link, and the updated preview.
   No tag, release, or marketplace issue has been created.
5. Read and confirm every checkbox in the draft, then change each to `[x]`
   only once true. Recheck current submission requirements and obtain the
   owner's approval of the completed title and body before posting.

## Submit after review

Use the [official form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml),
or run this from the repository root after the above review:

```bash
gh issue create \
  --repo omacom/omarchy-plugin-marketplace \
  --title '[Plugin]: Visual Keybindings' \
  --body-file docs/marketplace-submission.md
```

Keep the six headings and checklist wording intact. The unchecked draft
is deliberately not ready to submit until the owner confirms the statements.
Follow validation feedback on the same issue; listing requires maintainer
approval. A marketplace listing is not a security audit.
