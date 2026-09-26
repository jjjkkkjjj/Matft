---
name: release
description: Procedure for releasing a new version of Matft (decide the version → check tests → write release notes → create and push an annotated tag → publish a GitHub Release). Use this skill whenever the conversation is about bumping Matft's version, tagging, or creating/updating a GitHub Release — e.g. "bump the version", "cut a release", "ship 0.3.4", "tag it", "create the Release", "publish a new version", or in Japanese「バージョンアップして」「リリースして」「0.3.4 を出して」「タグ打って」「Releases 作って」「新しいバージョン公開」— even if the word "skill" is never mentioned.
---

# Matft release procedure

Matft is distributed via SwiftPM, and users resolve versions from **git tags in `x.x.x` form** (no `v` prefix — SwiftPM would no longer recognize it as a semantic version).
So the core of a release is "put the tag on the right commit, push it, and publish the GitHub Release tied to it".
CocoaPods (`Matft.podspec`) and Carthage are out of scope for this skill; do not touch them.

Pushing a tag and publishing a Release are public operations that immediately affect users' `Package.resolved`. They are hard to undo, so **always get the user's confirmation before running any publishing command**.

## 1. Pre-checks and choosing the commit to tag

A release is defined not by the working tree but by **the single commit to be tagged (`<commit>` below)**. All subsequent log, test, and CI checks are done against this `<commit>`. That way the release can proceed even if there are unrelated work-in-progress changes or unpushed operations-only commits locally.

```sh
git fetch origin --tags
git branch --show-current
git status --porcelain
git rev-list --left-right --count origin/main...HEAD   # "<only on origin> <only local>"
gh auth status
```

- `<commit>` is usually the tip of `origin/main` (`git rev-parse origin/main`). Specify it by hash, not branch name, so it does not move if the branch moves later.
- If there are unpushed local commits: check whether they contain code changes that should be in the release. If they are operations-only (e.g. adding CLAUDE.md), ignore them and target `origin/main`. If they are code changes, push them first (after user confirmation) or ask the user.
- Uncommitted changes are not included in the release as long as you tag an explicit `<commit>`. Mention "working tree changes are not included" when confirming.
- Stop only when the target cannot be determined, e.g. `gh` is not authenticated, or origin has commits you have not pulled and it is unclear which to ship.

## 2. Decide the version

```sh
git tag --sort=-v:refname | head -5                   # recent tags
git log --oneline <latest tag>..<commit>              # changes since the last release
```

- If the user specified a version, use it. Verify it is in `x.x.x` form, does not duplicate an existing tag, and is greater than the latest tag.
- Otherwise propose one from the changes: breaking changes (e.g. spec changes to match Numpy behavior) or new features → minor; bug fixes only → patch. It is 0.x, so leave the final decision to the user.

## 3. Check tests and CI

As CLAUDE.md requires, never release anything whose tests do not all pass. Running `swift test` in the working tree can fail because of uncommitted TDD-in-progress changes (tests in the Red state, etc.), so check out `<commit>` cleanly and test that.

```sh
git worktree add <scratchpad>/matft-release <commit>
(cd <scratchpad>/matft-release && swift test)
git worktree remove <scratchpad>/matft-release

gh run list --commit <commit>      # both the Swift and wasm workflows should be success
```

If the working tree is clean and HEAD equals `<commit>`, you may run `swift test` in place. If tests or CI fail, abort the release and report the cause.

## 4. Check for an existing draft Release

A draft Release with the same name (often without a tag) may already exist on GitHub with release notes written in advance. Reuse it rather than discarding it.

```sh
gh api repos/jjjkkkjjj/Matft/releases \
  --jq '.[] | select(.draft and .name=="<version>") | {id, name, tag_name, body}'
```

If found, note its `id` and `body`.

## 5. Write the release notes

Base them on `git log <latest tag>..<commit> --pretty='%h %s'`. If there is a draft body, start from it and add missing changes (things merged after the draft was created are often missing).

Commit subjects often contain only a number, like `fixed #47`. In that case look up the title to understand the change:

```sh
gh api repos/jjjkkkjjj/Matft/issues/<n> --jq '{title, pull_request: (.pull_request != null)}'
```

Follow the format of existing releases (`N/A` for empty sections):

```markdown
- New Features
  - Add `Matft.foo` (#100)
- Improvement
  - N/A
- Bug fixed
  - `Matft.bar` returns wrong shape for negative axis (#101)
```

- Write concisely in English. Wrap function names etc. in backquotes.
- Include only changes that affect library users (features, behavior, public API, warnings, etc. in `Sources/`). Leave out CI/workflow changes, test-only changes, documentation or operations changes such as README and CLAUDE.md, and merge commits.
- Append the related PR/issue numbers (`(#57, #58)` if several).

## 6. User confirmation

Present the results so far and get an explicit OK:

- Version number
- Commit to tag (hash and subject)
- Test / CI results
- Full release notes
- Whether to reuse the draft or create a new Release

## 7. Tag and push

```sh
git tag -a <version> -m "<version>" <commit>
git push origin <version>
```

Push the tag by name, not with `git push --tags`, so that stale or experimental tags left locally are not published along with it.

## 8. Publish the GitHub Release

Write the release notes to a temporary file (in the scratchpad) and pass that, to avoid escaping accidents with newlines and backquotes.

**If there is a draft** (a draft without a tag cannot be looked up by tag name with `gh release edit`, so update it through the API):

```sh
gh api -X PATCH repos/jjjkkkjjj/Matft/releases/<draft-id> \
  -f tag_name=<version> -f name=<version> \
  -f body="$(cat <notes-file>)" \
  -F draft=false -f make_latest=true
```

**If there is no draft**:

```sh
gh release create <version> --verify-tag --title <version> --notes-file <notes-file> --latest
```

`--verify-tag` makes it fail if the pushed tag does not exist, preventing gh from creating a tag on some other commit by itself.

## 9. Verify and report

```sh
gh release view <version>
gh release list --limit 3        # the new version should be Latest
git ls-remote --tags origin <version>
```

Report the Release URL and that SwiftPM users can get it via `File > Packages > Update to Latest Package Versions`.

## If you need to redo it

If a mistake is found after publishing, with the user's confirmation:

```sh
gh release delete <version> --yes        # delete the Release (if needed)
git tag --delete <version>
git push origin :refs/tags/<version>
```

Also tell the user that a published tag may already be cached on the users' side, so re-releasing under the next patch number is often safer than re-tagging the same number.
