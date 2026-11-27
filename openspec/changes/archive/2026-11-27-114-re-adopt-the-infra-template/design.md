# Design

## Decisions

- **The template owns each file that it renders, except five.** A change of a template file goes through an answer or through the template, so the next `copier update` has nothing to merge.
- **The answers hold the scopes and their descriptions.** `scope_descriptions` holds each description that differs from the template default, so each scope label keeps its text.
- **Standard callers for the title check and the release.** The template renders both callers, and `copier update` moves their pin. CODEOWNERS requests the review of the release pull request, so the caller passes no `reviewers`.

## Rejected alternatives

- **Resolve the conflicts in the Renovate copier pull request.** The hand edits stay, so the next copier update conflicts again (dan-petty/infra#225).
- **Keep the own `pr-title.yml` and `release.yml`.** The template renders the callers into both files, so each copier update conflicts with the own steps again.
