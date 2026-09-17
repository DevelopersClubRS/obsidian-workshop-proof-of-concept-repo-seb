#!/usr/bin/env python3
"""Build a workshop page: escape raw code blocks, emit the Artifact fragment and a standalone page.

  python3 build.py <artifact-out.html> <site-out.html>              # Hermes in the Vault (hermes-in-the-vault.src.html)
  python3 build.py <source.src.html> <artifact-out.html> <site-out.html>   # any page, e.g. hermes-managed.src.html
"""
import html, pathlib, re, sys

here = pathlib.Path(__file__).parent
if len(sys.argv) == 4:
    src_path, artifact_out, site_out = here / sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
else:
    src_path, artifact_out, site_out = here / "hermes-in-the-vault.src.html", pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
FAVICONS = {"hermes-in-the-vault": "%F0%9F%8C%8B", "hermes-managed": "%E2%98%81%EF%B8%8F"}  # volcano, cloud
favicon = FAVICONS.get(src_path.name.replace(".src.html", ""), "%F0%9F%8C%8B")

src = src_path.read_text()
# Code inside <pre class="code" ...><code>RAW</code></pre> is authored raw; escape it here.
built, n = re.subn(r'(<pre class="code"[^>]*><code>)(.*?)(</code></pre>)',
                   lambda m: m.group(1) + html.escape(m.group(2), quote=False) + m.group(3), src, flags=re.S)
head, body = built.split("<!--BODY-->", 1)
artifact_out.write_text(head + body)
site_out.write_text(
    '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
    f'<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22%3E%3Ctext y=%22.9em%22 font-size=%2290%22%3E{favicon}%3C/text%3E%3C/svg%3E">\n'
    + head.strip() + "\n</head>\n<body>\n" + body.strip() + "\n</body>\n</html>\n")
print(f"{src_path.name}: escaped {n} code blocks -> {artifact_out}, {site_out}")
