#!/usr/bin/env python3
"""Build the embedded client font CSS from the subset WOFF2 files.

The mobile UI uses the desktop client's Chill Round Gothic family. The
WOFF2 files in web-prototype/fonts are subset to GB2312 plus every glyph
used by the app/docs, then embedded as data URIs so Android, the iOS
loopback server and the Expo mock all load the same bytes.
"""

from __future__ import annotations

import base64
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = ROOT / "web-prototype" / "fonts"
OUT = ROOT / "web-prototype" / "fonts.css"

FACES = [
    ("ChillRoundGothic-Regular.woff2", "400"),
    ("ChillRoundGothic-Medium.woff2", "500 600"),
    ("ChillRoundGothic-Bold.woff2", "700 900"),
]

LICENSE = FONT_DIR / "OFL.txt"


def main() -> None:
    parts = [
        "/* Chill Round Gothic, from the O11A1 desktop client.",
        "   Subset to GB2312 + the characters used by the app and docs.",
        "   SIL Open Font License 1.1; the full license follows at the end. */",
    ]
    for name, weight in FACES:
        data = base64.b64encode((FONT_DIR / name).read_bytes()).decode("ascii")
        parts.append(
            "@font-face{"
            'font-family:"Chill Round Gothic";'
            f'src:url("data:font/woff2;base64,{data}") format("woff2");'
            f"font-weight:{weight};font-style:normal;font-display:swap;"
            "}"
        )
    if LICENSE.exists():
        parts.append("/*\n" + LICENSE.read_text(encoding="utf-8").strip() + "\n*/")
    OUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}  {OUT.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
