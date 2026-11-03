# GitHub settings

Settings that live in GitHub and are kept here as files.

## Rulesets

`rulesets/` holds the branch rulesets for the default branch.

| File | Use for |
|---|---|
| `main.json` | Repos without CI: pull request required, no deletion, no force push |
| `main-with-ci.json` | Repos with CI: the same, plus the required checks of the workflow |
