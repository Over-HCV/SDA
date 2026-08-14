#!/usr/bin/env python3
"""Convert RMarkdown-generated HTML (downcute/pandoc template) to clean Markdown.

For each input HTML file <name>.html, creates a folder <name>/ containing:
    main.md   - GitHub-flavored Markdown (text + code blocks)
    pics/     - images decoded from inline data URIs, referenced from main.md

Only the real notebook body (<div id="content">) is converted; the downcute
chrome (TOC sidebar, dark-mode toggle, nav) is discarded.

Usage:
    python3 html2md.py NB1_1_EST.html
    python3 html2md.py NB1_1_EST.html NB1_2_EST.html NB2_EST.html ...
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from bs4 import BeautifulSoup


def extract_content(html_path: Path) -> str:
    """Return inner HTML of <div id="content"> (the real notebook body)."""
    soup = BeautifulSoup(html_path.read_text(encoding="utf-8"), "html.parser")
    content = soup.find(id="content")
    if content is None:
        raise RuntimeError(f'No <div id="content"> found in {html_path}')
    return content.decode_contents()


def run_pandoc(content_html: str, out_dir: Path, pics_dir: Path) -> Path:
    """Write content_html to a temp file and run pandoc -> main.md, media -> pics_dir."""
    out_dir.mkdir(parents=True, exist_ok=True)
    pics_dir.mkdir(parents=True, exist_ok=True)
    main_md = out_dir / "main.md"

    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".html", delete=False, encoding="utf-8", dir=out_dir
    ) as tmp:
        tmp.write(content_html)
        tmp_path = Path(tmp.name)

    try:
        subprocess.run(
            [
                "pandoc",
                str(tmp_path),
                "-o", str(main_md),
                "--from", "html",
                "--to", "gfm",
                "--wrap", "none",
                "--extract-media", str(pics_dir),
            ],
            check=True,
        )
    finally:
        tmp_path.unlink(missing_ok=True)
    return main_md


def rename_images(main_md: Path, pics_dir: Path) -> int:
    """Rename referenced pics to img_NN.<ext> in order of appearance; fix refs.

    Returns the number of images kept (referenced from main.md)."""
    text = main_md.read_text(encoding="utf-8")

    # Match any reference whose path ends inside pics/ (GFM ![..](path) or HTML src="path").
    # Captures the basename actually used by pandoc.
    refs = []
    seen = set()

    def collect(m):
        path = m.group(1)
        # normalise to the segment after "pics/"
        m2 = re.search(r"(?:^|/)pics/(.+)$", path)
        name = m2.group(1) if m2 else Path(path).name
        if name not in seen:
            seen.add(name)
            refs.append(name)
        return None

    re.sub(r"!\[[^\]]*\]\(([^)]+)\)", collect, text)
    re.sub(r'src=["\']([^"\']+)["\']', collect, text)

    # Build rename map in order of appearance
    mapping = {}
    for i, old in enumerate(refs, 1):
        src = pics_dir / old
        if src.exists():
            ext = src.suffix or ".png"
            mapping[old] = f"img_{i:02d}{ext}"

    # Apply text replacements (full path -> pics/img_NN.ext)
    def replace(m):
        path = m.group(1)
        m2 = re.search(r"(?:^|/)pics/(.+)$", path)
        name = m2.group(1) if m2 else Path(path).name
        if name in mapping:
            return m.group(0).replace(path, f"pics/{mapping[name]}")
        return m.group(0)

    text = re.sub(r"!\[[^\]]*\]\(([^)]+)\)", replace, text)
    text = re.sub(r'src=["\']([^"\']+)["\']', replace, text)
    main_md.write_text(text, encoding="utf-8")

    # Perform file renames, then drop any unreferenced leftovers
    keep = set(mapping.values())
    for old, new in mapping.items():
        src = pics_dir / old
        dst = pics_dir / new
        if dst.exists():
            dst.unlink()
        shutil.move(str(src), str(dst))
    for f in pics_dir.iterdir():
        if f.is_file() and f.name not in keep:
            f.unlink()
    return len(mapping)


def process(html_path: Path) -> None:
    html_path = html_path.resolve()
    if not html_path.is_file():
        print(f"  ! no existe: {html_path}", file=sys.stderr)
        return
    out_dir = html_path.parent / html_path.stem
    pics_dir = out_dir / "pics"
    print(f"-> {html_path.name}  =>  {out_dir}/")
    content_html = extract_content(html_path)
    main_md = run_pandoc(content_html, out_dir, pics_dir)
    n = rename_images(main_md, pics_dir)
    print(f"   main.md ({main_md.stat().st_size} bytes), {n} imagenes en pics/")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    for arg in sys.argv[1:]:
        process(Path(arg))


if __name__ == "__main__":
    main()
