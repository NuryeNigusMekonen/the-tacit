<!-- Tenacious PR template (Standard §2). Fixes the "no description" problem:
     a PR must explain what changed and why - not restate the diff. -->

## What changed and why
<!-- Plain language: what this PR does and the reason for it. Required. -->


## Related task / issue
<!-- Link the ticket or issue, e.g. closes #123 -->


## How it was tested
<!-- What you ran / checked. New code should carry proportionate tests. -->


## Risk & scope
<!-- Does it touch sensitive areas (auth, migrations, billing, PII, shared utils, prompts)?
     Any behaviour change outside the stated scope? -->


## Checklist
- [ ] Description explains what & why (not a restatement of the diff)
- [ ] Tests added/updated for changed behaviour
- [ ] Lint / format / build pass locally
- [ ] No secrets, tokens, or credentials in the diff
- [ ] Sensitive areas (if touched) called out above
- [ ] Targets the correct branch per the branch policy (feature → dev → staging → main)
