# <functionName>

> Reference doc — Diátaxis mode: Reference. Replace every `<...>`. Do NOT invent types, parameters, or return values. If unknown, write `(to be documented)`.

## Audience
- **Primary:** <e.g. backend engineers calling this function> — expertise: <level>
- **Secondary:** <e.g. new hires reading the codebase>

## When to use
- <concrete triggering condition>
- <concrete triggering condition>

## When NOT to use
- <case where another function is more appropriate>
- <case where this function is overkill>

## Signature

```ts
function <functionName>(<param>: <type>, <opts>?: <type>): <returnType>;
```

## Parameters

### `<param>` — `<type>` *(required)*
<one-sentence description>. If the shape is unknown: `(to be documented)`.

| Field | Type | Required | Description |
|---|---|---|---|
| `<field>` | `<type>` | yes | <description> |
| `<field>` | `<type>` | no | <description> |

### `<opts>` — `<type>` *(optional)*
<one-sentence description>. If unknown: `(to be documented)`.

| Field | Type | Default | Description |
|---|---|---|---|
| `<field>` | `<type>` | `<default>` | <description> |

## Returns
`<returnType>` — <description>. If unknown: `(to be documented)`.

## Behavior
1. <numbered, active voice, what the function does>
2. <numbered>
3. <numbered>

## Errors
| Error | Condition |
|---|---|
| `<ErrorName>` | <when thrown> |
| `<ErrorName>` | <when thrown> |

## Examples

### <use case name>
```ts
import { <functionName> } from "<package>";

<minimal example, runnable>
```

### <use case name>
```ts
<example, runnable>
```

## Notes
- <gotcha, performance, concurrency — short bullets>

## See also
- [<related function>](<link or "(to be published)">)
- [<guide>](<link or "(to be published)">)