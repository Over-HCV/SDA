#!/usr/bin/env python3
"""Convert a generated Markdown folder back into an R Markdown (.Rmd) file.

For each input folder <name>/ (produced by html2md.py, containing main.md and
pics/), writes <name>/<name>.Rmd ready to knit in RStudio with rmdformats.

Transformations (mechanical; leaves prose intact for a later LLM cleanup pass):
    - first "# title" + "Profesor:" line  -> YAML header (downcute output)
    - ```r / ```R fences                   -> ```{r}  (Rmd code chunk)
    - indented console output "    ## ..." -> removed (regenerated on knit)
    - <div class="section levelN"> / </div>-> removed (pandoc noise)
    - <span class="glyphicon...">          -> removed
    - <img src="pics/.." alt="..">         -> ![alt](pics/..)
    - everything else (sections, lists,    -> kept as-is
      blockquotes, <br>, ---, bold/italic)

Usage:
    python3 md2rmd.py NB1_1_EST
    python3 md2rmd.py NB1_1_EST NB1_2_EST NB3 ...
    python3 md2rmd.py path/to/main.md
"""
import re
import sys
from pathlib import Path


def build_yaml(title: str, author: str) -> str:
    return (
        "---\n"
        f'title: "{title}"\n'
        f'author: "{author}"\n'
        "output:\n"
        "  rmdformats::downcute\n"
        "---\n\n"
    )


def extract_metadata(text: str) -> tuple[str, str, list[str]]:
    """Return (title, author, body_lines) pulling title + author out of the body."""
    lines = text.splitlines()
    title, author = "", "Profesor: Nicolás Lopez"

    # title = first "# ..." heading
    for i, ln in enumerate(lines):
        m = re.match(r"^#\s+(.+?)\s*$", ln)
        if m:
            title = m.group(1).strip()
            del lines[i]
            break

    # author = first line containing "Profesor:" (strip any leading span/icon)
    for i, ln in enumerate(lines):
        if "Profesor:" in ln:
            m = re.search(r"Profesor:\s*(.+?)\s*$", re.sub(r"<[^>]+>", "", ln))
            if m:
                author = "Profesor: " + m.group(1).strip()
            del lines[i]
            break

    return title, author, lines


def convert_img(line: str) -> str:
    def repl(m):
        tag = m.group(0)
        src_m = re.search(r'src="(pics/[^"]+)"', tag)
        if not src_m:
            return tag
        alt_m = re.search(r'alt="([^"]*)"', tag)
        alt = alt_m.group(1) if alt_m else ""
        return f"![{alt}]({src_m.group(1)})"

    return re.sub(r"<img\b[^>]*>", repl, line)


def transform_body(lines: list[str]) -> tuple[list[str], dict]:
    stats = {"chunks": 0, "outputs_removed": 0, "divs_removed": 0, "imgs": 0}
    out: list[str] = []
    in_code = False
    i = 0
    n = len(lines)
    while i < n:
        ln = lines[i]
        stripped = ln.strip()

        # --- code fence tracking ---
        if stripped.startswith("```"):
            if not in_code:
                lang = stripped[3:].strip()
                if lang.lower() == "r":
                    out.append("```{r}")
                    stats["chunks"] += 1
                else:
                    out.append(ln)
                in_code = True
                i += 1
                continue
            else:
                in_code = False
                out.append(ln)
                i += 1
                continue

        if in_code:
            out.append(ln)
            i += 1
            continue

        # --- remove console output blocks: "    ## ..." (+ one trailing blank) ---
        if re.match(r"^    ## ", ln):
            while i < n and re.match(r"^    ## ", lines[i]):
                stats["outputs_removed"] += 1
                i += 1
            if i < n and lines[i].strip() == "":
                i += 1  # swallow the single blank right after the output
            continue

        # --- remove section-wrapper divs and their closes ---
        if re.match(r"^</?div[\s>]", ln):
            stats["divs_removed"] += 1
            i += 1
            continue

        # --- remove glyphicon icon spans ---
        if re.match(r'^<span class="glyphicon', ln):
            i += 1
            continue

        # --- convert <img ...> to markdown image ---
        if "<img" in ln:
            new = convert_img(ln)
            if new != ln:
                stats["imgs"] += len(re.findall(r"<img\b", ln))
            ln = new

        out.append(ln)
        i += 1

    return out, stats


def process(target: Path) -> None:
    # accept either a folder (containing main.md) or a main.md path
    if target.is_dir():
        main_md = target / "main.md"
        stem = target.name
    else:
        main_md = target
        stem = target.parent.name
    if not main_md.is_file():
        print(f"  ! no existe: {main_md}", file=sys.stderr)
        return

    text = main_md.read_text(encoding="utf-8")
    title, author, body = extract_metadata(text)
    body, stats = transform_body(body)

    out_dir = main_md.parent
    rmd = out_dir / f"{stem}.Rmd"
    with rmd.open("w", encoding="utf-8") as f:
        f.write(build_yaml(title, author))
        # collapse 3+ blank lines down to 2 for tidiness
        body_text = "\n".join(body)
        body_text = re.sub(r"\n{3,}", "\n\n", body_text)
        f.write(body_text)
        if not body_text.endswith("\n"):
            f.write("\n")

    print(f"-> {main_md.parent.name}/  =>  {rmd.name}")
    print(f'   title="{title}"  author="{author}"')
    print(f"   chunks R: {stats['chunks']} | outputs eliminados: {stats['outputs_removed']}"
          f" | divs: {stats['divs_removed']} | imgs: {stats['imgs']}")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    for arg in sys.argv[1:]:
        process(Path(arg))


if __name__ == "__main__":
    main()
