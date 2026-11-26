#!/usr/bin/env bash
# Generate the GitHub wiki pages from this repository's source tree.
# Usage: bash scripts/generate-wiki.sh [output-directory]   (default: wiki-out)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-wiki-out}"

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required (on NixOS: nix shell nixpkgs#python3 --command bash $0 $OUT_DIR)" >&2
	exit 1
fi

mkdir -p "$OUT_DIR"

python3 - "$REPO_ROOT" "$OUT_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
out = Path(sys.argv[2])

PAGES = [
    "Home.md",
    "Install.md",
    "System-Modules.md",
    "User-Modules.md",
    "Hardware.md",
    "Development.md",
]

KEYWORDS = {
    "if", "then", "else", "with", "or", "let", "in", "inherit", "rec", "assert",
    "true", "false", "null", "cfg", "config", "lib", "self", "inputs",
}
PKG_HELPERS = {
    "lib", "callPackage", "stdenv", "fetchFromGitHub", "fetchurl", "symlinkJoin",
    "runCommand", "runCommandLocal", "writeShellScriptBin", "mkShell", "newScope",
    "override", "overrideAttrs", "optionals", "optional", "optionalString",
    "concatStringsSep", "concatMapStringsSep", "filterAttrs", "mapAttrs",
    "attrNames", "listToAttrs", "nameValuePair", "toString", "recurseIntoAttrs",
    "makeWrapper", "wrapProgram", "writeText", "writeShellApplication",
}


def read(rel: str) -> str:
    path = root / rel
    return path.read_text(errors="replace") if path.is_file() else ""


def no_comments(src: str) -> str:
    return re.sub(r"(?m)^\s*#.*$", "", src)


def decorative(text: str) -> bool:
    return bool(re.match(r"^[─=-]{2,}", text) or re.search(r"[─=-]{2,}$", text))


def escape_tags(text: str) -> str:
    """Escape <placeholder> outside code spans so GitHub renders it literally."""
    def replace_outside_spans(line: str) -> str:
        parts: list[str] = []
        pos = 0
        for span in re.finditer(r"`[^`]*`", line):
            head = line[pos : span.start()]
            parts.append(re.sub(r"<([A-Za-z][A-Za-z0-9_.-]*)>", r"\\<\1\\>", head))
            parts.append(span.group(0))
            pos = span.end()
        parts.append(re.sub(r"<([A-Za-z][A-Za-z0-9_.-]*)>", r"\\<\1\\>", line[pos:]))
        return "".join(parts)

    out: list[str] = []
    in_fence = False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_fence = not in_fence
            out.append(line)
        elif in_fence:
            out.append(line)
        else:
            out.append(replace_outside_spans(line))
    return "\n".join(out)


def format_comment(lines: list[str]) -> str:
    """Render a leading comment block as paragraphs, code spans and lists."""
    blocks: list[str] = []
    paragraph: list[str] = []
    items: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            blocks.append(" ".join(paragraph))
            paragraph.clear()

    def flush_items() -> None:
        if items:
            blocks.append("\n".join(items))
            items.clear()

    for line in lines:
        body = line.strip()
        if not body or decorative(body):
            flush_items()
            flush_paragraph()
            continue
        number = re.match(r"^(\d+)\.\s+(.*)$", body)
        if number:
            flush_paragraph()
            items.append(f"{number.group(1)}. {number.group(2)}")
            continue
        flush_items()
        if len(line) - len(line.lstrip()) >= 2 and "`" not in body:
            flush_paragraph()
            blocks.append(f"`{body}`")
            continue
        paragraph.append(body)

    flush_items()
    flush_paragraph()
    return "\n\n".join(blocks)


def first_comment(rel: str) -> str:
    """Only the leading comment block counts; shebangs are skipped."""
    lines: list[str] = []
    for raw in read(rel).splitlines():
        stripped = raw.strip()
        if not lines and stripped.startswith("#!"):
            continue
        if stripped.startswith("#"):
            lines.append(stripped.lstrip("#").rstrip())
            continue
        break
    return escape_tags(format_comment(lines)).rstrip(";").strip()


def one_line(value: str) -> str:
    return re.sub(r"\s*\n\s*", " ", value).strip()


def brace_block(src: str, start: int) -> str:
    """Return the contents of the {...} starting at `start`."""
    depth = 0
    for i in range(start, len(src)):
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                return src[start + 1 : i]
    return src[start + 1 :]


def nix_string(value: str) -> str:
    return value.replace('\\"', '"').replace("\\\\", "\\")


def esc(value: str) -> str:
    return escape_tags(re.sub(r"(?<!\\)\|", r"\\|", nix_string(value))).strip()


def bullet_list(values, indent="") -> list[str]:
    return [f"{indent}- `{value}`" for value in values]


def short_list(values, limit=12) -> str:
    if len(values) <= limit:
        return ", ".join(f"`{value}`" for value in values)
    return ", ".join(f"`{value}`" for value in values[:limit]) + f" … (+{len(values) - limit})"


# --------------------------------------------------------------------------- #
# Extractors
# --------------------------------------------------------------------------- #

def flake_inputs() -> list[tuple[str, str, str]]:
    src = read("flake.nix")
    match = re.search(r"\binputs\s*=\s*\{", src)
    if not match:
        return []
    block = brace_block(src, src.index("{", match.start()))
    starts = [
        (m.start(), m.group(1))
        for m in re.finditer(
            r"(?m)^    ([A-Za-z0-9_-]+)(?:\.url)?\s*=", block
        )
    ]
    rows = []
    for index, (pos, name) in enumerate(starts):
        end = starts[index + 1][0] if index + 1 < len(starts) else len(block)
        chunk = block[pos:end]
        url = re.search(r'\burl\s*=\s*"([^"]+)"', chunk)
        follows = re.findall(r'inputs\.([\w-]+)\.follows\s*=\s*"([^"]+)"', chunk)
        rows.append(
            (
                name,
                url.group(1) if url else "",
                ", ".join(f"{source} → {target}" for source, target in follows),
            )
        )
    return sorted(rows)


def depth_at(text: str, pos: int) -> int:
    """Brace depth at `pos`, ignoring braces inside strings and comments."""
    depth = 0
    i = 0
    while i < pos:
        char = text[i]
        if text[i : i + 2] == "''":
            end = i + 2
            while end < len(text):
                if text[end : end + 2] == "''" and text[end + 2 : end + 3] != "$":
                    break
                end += 1
            i = end + 2 if end < len(text) else len(text)
            continue
        if char == '"':
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if char == "#":
            end = text.find("\n", i)
            i = end if end != -1 else len(text)
            continue
        if char in "{[(":
            depth += 1
        elif char in "}])":
            depth -= 1
        i += 1
    return depth


def indented_string(text: str) -> str:
    """Read a Nix ''...'' string starting at `text[0]`, honouring ''${ escapes."""
    parts: list[str] = []
    i = 2
    while i < len(text):
        if text[i : i + 4] == "''${":
            parts.append("${")
            i += 4
            continue
        if text[i : i + 2] == "''":
            break
        parts.append(text[i])
        i += 1
    lines = "".join(parts).splitlines()
    indents = [len(line) - len(line.lstrip()) for line in lines if line.strip()]
    pad = min(indents) if indents else 0
    return re.sub(r"\s+", " ", "\n".join(line[pad:] for line in lines)).strip()


def description_of(block: str) -> str:
    """Description of this option, not one from a nested submodule."""
    candidates = [
        (depth_at(block, match.start()), match.end())
        for match in re.finditer(r"\bdescription\s*=\s*", block)
    ]
    if not candidates:
        return ""
    _, start = min(candidates, key=lambda item: item[0])
    rest = block[start:].lstrip()
    if rest.startswith("''"):
        return indented_string(rest)
    match = re.match(r'"((?:[^"\\]|\\.)*)"', rest)
    return nix_string(match.group(1)) if match else ""


def walk_options(block: str, prefix: str, found: dict[str, str]) -> None:
    """Walk an attrset of options, keeping the full dotted path."""
    lines = block.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        match = re.match(r"^\s*([A-Za-z0-9_.-]+)\s*=\s*(.*)$", line)
        if not match:
            index += 1
            continue

        name, rhs = match.group(1), match.group(2).strip()
        indent = len(line) - len(line.lstrip())
        end = index + 1
        while end < len(lines):
            following = lines[end]
            if not following.strip():
                end += 1
                continue
            next_indent = len(following) - len(following.lstrip())
            if next_indent <= indent and (
                re.match(r"^\s*[A-Za-z0-9_.-]+\s*=", following)
                or following.strip().startswith("}")
            ):
                break
            end += 1

        value = "\n".join([rhs] + lines[index + 1 : end])
        path = f"{prefix}.{name}" if prefix else name

        if rhs.startswith("lib.mkEnableOption"):
            desc = re.match(r'lib\.mkEnableOption\s*"((?:[^"\\]|\\.)*)"', value)
            found[path] = nix_string(desc.group(1)) if desc else ""
        elif rhs.startswith("lib.mkOption"):
            nested = brace_block(value, value.index("{"))
            found[path] = description_of(nested)
            for sub in re.finditer(r"\boptions\s*=\s*\{", nested):
                walk_options(brace_block(nested, nested.index("{", sub.start())), path, found)
        elif "{" in value:
            nested = brace_block(value, value.index("{"))
            for sub in re.finditer(r"\boptions\s*=\s*\{", nested):
                walk_options(brace_block(nested, nested.index("{", sub.start())), path, found)
            if not re.search(r"\boptions\s*=\s*\{", nested):
                walk_options(nested, path, found)
        index = end


def options_of(src: str) -> list[tuple[str, str]]:
    found: dict[str, str] = {}
    for match in re.finditer(r"options\.([A-Za-z0-9_.+-]+)\s*=\s*", src):
        path = match.group(1)
        tail = src[match.end() :]
        body = tail.lstrip()
        if body.startswith("lib.mkEnableOption"):
            desc = re.match(r'lib\.mkEnableOption\s*"((?:[^"\\]|\\.)*)"', body)
            if desc:
                found[path] = nix_string(desc.group(1))
        elif body.startswith("lib.mkOption"):
            found[path] = description_of(brace_block(tail, tail.index("{")))
        elif body.startswith("{"):
            walk_options(brace_block(tail, tail.index("{")), path, found)
    return sorted(found.items())


def enables_of(src: str) -> list[str]:
    pattern = (
        r"\b((?:services|programs|security|xdg|fonts|boot\.loader)"
        r"\.[A-Za-z0-9_.-]+)\.enable\s*=\s*true"
    )
    return sorted(set(re.findall(pattern, no_comments(src))))


def packages_of(src: str) -> list[str]:
    source = no_comments(src)
    # Examples/literal expressions are not installed packages: drop string
    # contents before looking for `pkgs.<name>` references.
    source = re.sub(r"''(?:[^']|'(?!'))*''", "''", source, flags=re.S)
    source = re.sub(r'"(?:[^"\\]|\\.)*"', '""', source)
    names: set[str] = set()
    for match in re.finditer(r"with\s+pkgs(?:\.[\w-]+)?\s*;\s*\[", source):
        nest = 0
        body: list[str] = []
        for char in source[match.end() :]:
            if char in "([{":
                nest += 1
            elif char in ")]}":
                if not nest:
                    break
                nest -= 1
            elif not nest:
                body.append(char)
        for token in "".join(body).split():
            if re.fullmatch(r"[A-Za-z_][\w+-]*", token) and token not in KEYWORDS:
                names.add(token)
    # `with pkgs.<set>; [ ... ]` lists members of an attrset, not the set itself.
    sets = set(re.findall(r"with\s+pkgs\.([A-Za-z_][\w-]*)\s*;\s*\[", source))
    names -= sets
    for name in re.findall(r"\bpkgs\.([A-Za-z_][\w-]*)", source):
        if name not in PKG_HELPERS and name not in KEYWORDS and name not in sets:
            names.add(name)
    return sorted(names)


def setting_enables(src: str, root_key: str) -> list[str]:
    """List `*.enable = true` leaves inside a root attrset, with full dotted paths."""
    match = re.search(rf"\b{re.escape(root_key)}\s*=\s*\{{", src)
    if not match:
        return []
    block = brace_block(src, src.index("{", match.start()))
    stack: list[str] = []
    found: set[str] = set()
    for raw in block.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        opening = re.match(r"([A-Za-z0-9_.-]+)\s*=\s*\{", line)
        if opening:
            stack.append(opening.group(1))
            continue
        leaf = re.match(r"([A-Za-z0-9_.-]+\.)?enable\s*=\s*true\s*;", line)
        if leaf:
            found.add(".".join([root_key] + stack + [leaf.group(1) or "", "enable"]).replace("..", "."))
        for _ in range(line.count("}")):
            if stack:
                stack.pop()
    return sorted(found)


def nix_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(directory.rglob("*.nix"))


# --------------------------------------------------------------------------- #
# Page builders
# --------------------------------------------------------------------------- #

def anchor(text: str) -> str:
    return re.sub(r"[^a-z0-9 -]", "", text.lower()).replace(" ", "-")


def write_page(name: str, lines: list[str]) -> None:
    body = list(lines)
    if name != "Home.md" and not any("[← Home](Home)" in line for line in body):
        body.extend(["", "---", "", "[← Home](Home)"])
    body.extend(
        ["", "_Generated automatically by `scripts/generate-wiki.sh`; do not edit manually._"]
    )
    (out / name).write_text("\n".join(body).rstrip() + "\n")


def enrich_option(desc: str, comment: str) -> str:
    """Give bare one-word descriptions context from the module's own comment."""
    bare = desc.strip()
    if not comment or " " in bare or len(bare) > 15:
        return desc
    sentence = re.split(r"(?<=[a-z])\.\s+(?=[A-Z])", one_line(comment), maxsplit=1)[0]
    first = sentence.rstrip(".") + "."
    if len(first) > 100:
        return desc
    if sentence.split()[0].rstrip(":").lower() == bare.lower():
        return first
    return f"{bare} — {first}"


def render_module_page(title: str, base: str, source: str) -> None:
    lines = [
        f"# {title}",
        "",
        f"_Generated from `{source}/`. Do not edit this page by hand._",
        "",
        "Enable options are declared per module; set them under "
        "`systemSettings.<name>.enable` or `userSettings.<name>.enable` in the host configuration.",
        "",
    ]
    base_path = root / base
    categories = sorted(p for p in base_path.iterdir() if p.is_dir() and p.name != "hardware")
    root_files = sorted(p for p in base_path.glob("*.nix") if p.name != "default.nix")

    def collect(files: list[Path]) -> list[tuple[str, list, list, list]]:
        entries: list[tuple[str, list, list, list]] = []
        for path in files:
            rel = path.relative_to(root).as_posix()
            src = read(rel)
            comment = first_comment(rel)
            opts = [(opt, enrich_option(desc, comment)) for opt, desc in options_of(src)]
            enables = enables_of(src)
            packages = packages_of(src)
            if not (opts or enables or packages or comment):
                continue
            entries.append((rel, opts, enables, packages))
        return entries

    sections: list[tuple[str, list]] = []
    for category in categories:
        entries = collect(nix_files(category))
        if entries:
            sections.append((category.name, entries))
    core = collect(root_files)
    if core:
        sections.append(("Core", core))

    if len(sections) > 1:
        lines.extend(["## Contents", ""])
        for heading, entries in sections:
            count = len(entries)
            lines.append(
                f"- [{heading}](#{anchor(heading)}) — {count} module{'s' if count != 1 else ''}"
            )
        lines.append("")

    for heading, entries in sections:
        lines.extend([f"## {heading}", ""])
        for rel, opts, enables, packages in entries:
            lines.extend([f"### `{rel}`", ""])
            description = first_comment(rel)
            if description:
                lines.extend([description, ""])
            if opts:
                lines.extend(["| Option | Description |", "|---|---|"])
                for option, desc in opts:
                    lines.append(f"| `{option}` | {esc(desc)} |")
                lines.append("")
            if enables:
                lines.append(f"**Enables:** {short_list(enables)}")
                lines.append("")
            if packages:
                lines.append(f"**Packages:** {short_list(packages)}")
                lines.append("")
    write_page(f"{title.replace(' ', '-')}.md", lines)


def render_home() -> None:
    flake_src = read("flake.nix")
    description = re.search(r'\bdescription\s*=\s*"([^"]+)"', flake_src)
    title = description.group(1) if description else "NixOS Configuration"

    lines = [
        f"# {title}",
        "",
        "_This wiki is generated from the repository by `scripts/generate-wiki.sh`. "
        "Do not edit these pages by hand — edit the Nix files instead._",
        "",
        "## Pages",
        "",
        "- [Install and configuration](Install) — fresh install, storage/LUKS/TPM2, agenix, module options",
        "- [System modules](System-Modules) — options, enabled services and packages per module",
        "- [User modules](User-Modules) — Home Manager modules and their options",
        "- [Hardware](Hardware) — per-host hardware profiles and reusable hardware modules",
        "- [Development](Development) — templates, cache/proxy tooling, workflows",
        "",
        "The repository `README.md` is only a quickstart. The long-form guide is "
        "maintained in `docs/install.md` and published here as the Install page.",
        "",
        "## Hosts",
        "",
        "| Host | Files | Enabled settings | Hardware profile |",
        "|---|---|---:|---|",
    ]

    hosts_dir = root / "hosts"
    hosts = sorted(p for p in hosts_dir.iterdir() if p.is_dir()) if hosts_dir.is_dir() else []
    for host in hosts:
        files = sorted(p.relative_to(root).as_posix() for p in host.rglob("*.nix"))
        config = read(f"hosts/{host.name}/configuration.nix")
        enabled = set(setting_enables(config, "systemSettings")) | set(
            setting_enables(config, "userSettings")
        )
        profiles = sorted(
            p.relative_to(root).as_posix()
            for p in (host / "hardware").glob("*.nix")
        ) if (host / "hardware").is_dir() else []
        lines.append(
            f"| `{host.name}` | {len(files)} | {len(enabled)} | "
            f"{', '.join(f'`{p}`' for p in profiles) or '—'} |"
        )

    lines.extend(["", "## Flake inputs", "", "| Input | URL | Follows |", "|---|---|---|"])
    for name, url, follows in flake_inputs():
        lines.append(f"| `{name}` | {esc(url)} | {esc(follows)} |")

    secrets = sorted(p.name for p in (root / "secrets").glob("*.age")) if (root / "secrets").is_dir() else []
    if secrets:
        lines.extend(
            [
                "",
                "## Secrets",
                "",
                "Encrypted with [agenix](https://github.com/ryantm/agenix). "
                "Only the file names are listed here; contents are never copied into the wiki.",
                "",
            ]
        )
        lines.extend(bullet_list(secrets))

    lines.extend(
        [
            "",
            "## Deploy",
            "",
            "```bash",
            "sudo nixos-rebuild switch --flake .#nixyo",
            "# or, with systemSettings.nh enabled and flake set in the host config:",
            "sudo nh os switch",
            "```",
        ]
    )
    write_page("Home.md", lines)


def render_install() -> None:
    source = read("docs/install.md")
    lines = [
        "# Installation and configuration guide",
        "",
        "_Generated from `docs/install.md`. Do not edit this wiki page by hand — "
        "edit the file in the repository instead._",
        "",
        "[← Home](Home)",
        "",
    ]
    if source:
        lines.append(escape_tags(source.strip()))
    else:
        lines.append("_`docs/install.md` is missing — add it to the repository._")
    write_page("Install.md", lines)


def render_hardware() -> None:
    lines = [
        "# Hardware",
        "",
        "_Generated from `modules/system/hardware/` and `hosts/*/hardware/`. "
        "Do not edit manually._",
        "",
        "## Host profiles",
        "",
        "| Host | Profile | CPU | GPU |",
        "|---|---|---|---|",
    ]
    hosts_dir = root / "hosts"
    for host in sorted(p for p in hosts_dir.iterdir() if p.is_dir()) if hosts_dir.is_dir() else []:
        hw_dir = host / "hardware"
        for profile in sorted(hw_dir.glob("*.nix")) if hw_dir.is_dir() else []:
            src = read(profile.relative_to(root).as_posix())
            cpu = re.search(r'\bcpuVendor\s*=\s*"([^"]+)"', src)
            gpu = re.search(r'\bgpuVendor\s*=\s*"([^"]+)"', src)
            lines.append(
                f"| `{host.name}` | `{profile.name}` | "
                f"{cpu.group(1) if cpu else '—'} | {gpu.group(1) if gpu else '—'} |"
            )

    lines.extend(["", "## Modules", ""])
    for path in nix_files(root / "modules/system/hardware"):
        rel = path.relative_to(root).as_posix()
        src = read(rel)
        lines.extend([f"### `{rel}`", ""])
        description = first_comment(rel)
        if description:
            lines.extend([description, ""])
        opts = [(opt, enrich_option(desc, description)) for opt, desc in options_of(src)]
        enables = enables_of(src)
        packages = packages_of(src)
        if opts:
            lines.extend(["| Option | Description |", "|---|---|"])
            for option, desc in opts:
                lines.append(f"| `{option}` | {esc(desc)} |")
            lines.append("")
        if enables:
            lines.append(f"**Enables:** {short_list(enables)}")
            lines.append("")
        if packages:
            lines.append(f"**Packages:** {short_list(packages)}")
            lines.append("")
    write_page("Hardware.md", lines)


def render_development() -> None:
    lines = [
        "# Development",
        "",
        "_Generated from `templates/`, `lib/`, `proxy/` and `.github/workflows/`. "
        "Do not edit manually._",
        "",
        "## Wiki automation",
        "",
        "`.github/workflows/update-wiki.yml` runs on pushes to `main` that touch the "
        "source directories and on manual dispatch. It runs `scripts/generate-wiki.sh`, "
        "checks out `<repo>.wiki`, copies the generated pages and pushes them as "
        "`github-actions[bot]`. Wiki pages are therefore a build artifact, not a second "
        "place to maintain documentation — manual edits in the wiki are overwritten.",
        "",
        "## Templates",
        "",
    ]
    for path in sorted((root / "templates").rglob("*")) if (root / "templates").is_dir() else []:
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        description = one_line(first_comment(rel))
        lines.append(f"- `{rel}`" + (f" — {description}" if description else ""))

    for heading, directory in [
        ("Library helpers", "lib"),
        ("Binary cache proxy", "proxy"),
    ]:
        lines.extend(["", f"## {heading}", ""])
        for path in sorted((root / directory).rglob("*")) if (root / directory).is_dir() else []:
            if not path.is_file():
                continue
            rel = path.relative_to(root).as_posix()
            description = one_line(first_comment(rel))
            lines.append(f"- `{rel}`" + (f" — {description}" if description else ""))

    lines.extend(["", "## Workflows", ""])
    for path in sorted((root / ".github/workflows").glob("*.yml")):
        rel = path.relative_to(root).as_posix()
        name = re.search(r'(?m)^name:\s*(.+)$', read(rel))
        lines.append(f"- `{rel}` — {name.group(1).strip() if name else path.stem}")

    lines.extend(
        [
            "",
            "## Local generation",
            "",
            "On NixOS (no `python3` on PATH by default):",
            "",
            "```bash",
            "nix shell nixpkgs#python3 --command bash scripts/generate-wiki.sh /tmp/wiki-out",
            "```",
            "",
            "On a machine with `python3` already available (e.g. GitHub Actions `ubuntu-latest`):",
            "",
            "```bash",
            "bash scripts/generate-wiki.sh /tmp/wiki-out",
            "```",
            "",
            "The workflow commits with `[skip ci]` so a wiki update cannot trigger another run.",
        ]
    )
    write_page("Development.md", lines)


render_home()
render_install()
render_module_page("System Modules", "modules/system", "modules/system")
render_module_page("User Modules", "modules/user", "modules/user")
render_hardware()
render_development()

print(f"Generated {len(PAGES)} wiki pages in {out}")
PY
