# Edit Templates Workflow

Use this when changing reusable templates, scaffolds, shell files, hooks, protocol blocks, sample workflows, or any file that downstream projects will copy rather than merely read.

## Mandatory Pre-Step (cannot skip)

**Re-run `SKILL.md` § Session Discipline before starting.** Re-match the request, then read the template boundary docs before touching any reusable artifact.

## Read First

1. Re-open `SKILL.md` → match this change to a Common Tasks route
2. Read `rules/project-rules.md` and `rules/coding-standards.md`
3. Read the project template guide if present (for this meta-skill: `templates/README.md`)
4. Read the anti-template/admission rules if present (for this meta-skill: `templates/ANTI-TEMPLATES.md`)
5. Read task-relevant `references/*.md` for compatibility or host-specific constraints

## Admission Tests

Before editing, answer these out loud in your working notes:

1. **Would two real projects disagree?** If yes, the content probably belongs behind a project-specific placeholder marker, in project docs, or in a workflow note — not as pre-filled template content.
2. **Is this structure reusable while content stays project-specific?** Templates may prescribe shape and protocol; they must not smuggle project-specific examples as defaults.
3. **Does this increase always-read cognitive load?** If yes, require evidence of a real miss or an equal-weight removal before adding it.
4. **Is this a mechanism or a preference?** Mechanisms like sync scripts, protocol blocks, or checks are better template candidates than style preferences.

If any answer blocks the change, stop and propose the correct destination instead of weakening the template boundary.

## Steps

1. **Classify the artifact** — shell, hook, protocol block, workflow, rule template, reference template, migration helper, or checklist.
2. **Edit structure before content** — keep reusable structure; leave project-specific decisions as placeholder markers or instructions.
3. **Update paired files** — if a template has a shell/config/registration pair, update all paired files in the same change.
4. **Update routing or indexes** — if the new template/workflow must be discoverable, update `SKILL.md`, reference indexes, or canonical routing sources.
5. **Instantiate a temporary sample** — copy the template into a throwaway project or temp directory, fill required placeholders minimally, and run the relevant smoke checks.
6. **Check placeholder policy** — intentional placeholder markers may remain in templates; generated sample output must not retain unresolved placeholders.
7. **Run Task Closure Protocol** from `workflows/update-rules.md` — especially check whether this change reveals a missing template boundary rule.

## Completion Checklist

- [ ] `templates/README.md` or equivalent guide was read
- [ ] Anti-template/admission rules were applied
- [ ] Pre-filled content is reusable across at least two plausible projects
- [ ] Paired shell/config/registration files are synchronized
- [ ] Routing/index updates completed when discoverability changed
- [ ] Temporary instantiated sample passes smoke or equivalent validation
- [ ] Task Closure Protocol was run

<!-- FILL: project-specific sample-instantiation command and validation command. -->
