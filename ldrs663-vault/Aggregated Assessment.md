---
created: 2025-07-22T14:21
updated: 2025-07-23T09:56
---

```dataviewjs

const levels = ["not demonstrated", "emerging", "developing", "proficient", "extending"];
dv.table(
  ["Outcome", ...levels],
  dv.pages()
    .where(p => p.aggregate && !p.file.path.startsWith("_templates/"))
    .sort(p => p.file.name, 'asc')
    .map(p => {
      const counts = levels.map(l => (Array.isArray(p.aggregate) ? p.aggregate.filter(v => v === l).length : 0));
      return [p.file.link, ...counts];
    })
);

