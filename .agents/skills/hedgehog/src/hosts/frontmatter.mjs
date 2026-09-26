// Minimal YAML frontmatter reader/writer for the agent and skill files.
//
// The payload's frontmatter is a flat block of `key: value` scalars — no
// nesting, no lists, no anchors — so a full YAML parser would be a
// dependency bought for nothing. This handles exactly that shape and
// leaves the body untouched.

const FENCE = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/;

/** Split a file into its frontmatter object and its body. */
export function parse(text) {
  const m = text.match(FENCE);
  if (!m) return { data: {}, body: text };

  const data = {};
  for (const line of m[1].split(/\r?\n/)) {
    // `description:` values routinely contain colons, so split on the
    // first one only.
    const at = line.indexOf(':');
    if (at === -1 || line.startsWith('#')) continue;
    const key = line.slice(0, at).trim();
    let value = line.slice(at + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (key) data[key] = value;
  }
  return { data, body: text.slice(m[0].length) };
}

// Quote only when a value would otherwise change meaning as bare YAML.
// Descriptions commonly contain `: ` and `#`, both of which need it.
function scalar(value) {
  const s = String(value);
  const needsQuote = /:\s|^\s|\s$|^[[{>|*&!%@`'"]|#\s|\r|\n/.test(s) || s === '';
  return needsQuote ? `"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"` : s;
}

/** Rebuild a file from a frontmatter object and a body, key order preserved. */
export function stringify(data, body) {
  const lines = Object.entries(data)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}: ${scalar(v)}`);
  return `---\n${lines.join('\n')}\n---\n${body}`;
}
