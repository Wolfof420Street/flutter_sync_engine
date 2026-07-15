# Remove/rename Drift migration fixture

The committed baseline includes `Task.tags`; the fixture source renames it to
`labels`, simultaneously adding a new field and removing the old one.
Generation must fail with `Additive-only Drift migration rejected for Task:
removed or renamed field(s) tags.`
