"""Validate Pages output and SemVer release metadata without third-party packages."""

from __future__ import annotations

import argparse
import re
from html.parser import HTMLParser
from pathlib import Path

_VERSION = re.compile(
    r"(?m)^version:\s*(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:\+[0-9]+)?\s*$"
)


def expected_release_tag(pubspec_text: str) -> str:
    """Return the vMAJOR.MINOR.PATCH tag represented by pubspec.yaml."""
    match = _VERSION.search(pubspec_text)
    if match is None:
        raise ValueError("pubspec.yaml must define a SemVer version with optional +build metadata")
    return "v" + ".".join(match.groups())


def validate_release_tag(tag: str, pubspec_text: str) -> str:
    """Require a release tag to exactly match the version in pubspec.yaml."""
    expected = expected_release_tag(pubspec_text)
    if tag != expected:
        raise ValueError(f"Release tag {tag!r} must match pubspec.yaml version {expected!r}")
    return expected


class _PagesContract(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.base_hrefs: list[str] = []
        self.has_flutter_bootstrap = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag.lower() == "base" and values.get("href") is not None:
            self.base_hrefs.append(values["href"] or "")
        if tag.lower() == "script" and values.get("src", "").split("?", 1)[0].endswith(
            "flutter_bootstrap.js"
        ):
            self.has_flutter_bootstrap = True


def validate_pages_html(html: str, expected_base_path: str) -> None:
    """Require the deployed Flutter page to use its repo path and bootstrap."""
    if not expected_base_path.startswith("/") or not expected_base_path.endswith("/"):
        raise ValueError("expected base path must start and end with '/'")
    contract = _PagesContract()
    contract.feed(html)
    if expected_base_path not in contract.base_hrefs:
        raise ValueError(
            f"Published page must contain base href {expected_base_path!r}; "
            f"found {contract.base_hrefs!r}"
        )
    if not contract.has_flutter_bootstrap:
        raise ValueError("Published page must load flutter_bootstrap.js")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pubspec", type=Path, help="validate release version from this pubspec.yaml")
    parser.add_argument("--tag", default="", help="Git tag to validate on tag push")
    parser.add_argument("--event-name", default="pull_request")
    parser.add_argument("--output", type=Path, help="append release_tag output for GitHub Actions")
    parser.add_argument("--pages-html", type=Path, help="validate a downloaded Pages index.html")
    parser.add_argument("--base-path", default="/universal-ssh/")
    args = parser.parse_args()

    if args.pubspec:
        pubspec_text = args.pubspec.read_text(encoding="utf-8")
        tag = (
            validate_release_tag(args.tag, pubspec_text)
            if args.event_name == "push"
            else expected_release_tag(pubspec_text)
        )
        print(
            f"Validated release tag {tag}"
            if args.event_name == "push"
            else f"PR preview target: {tag}"
        )
        if args.output:
            with args.output.open("a", encoding="utf-8") as output:
                output.write(f"release_tag={tag}\n")

    if args.pages_html:
        validate_pages_html(args.pages_html.read_text(encoding="utf-8"), args.base_path)
        print(f"Published Pages HTML satisfies base path {args.base_path} and Flutter bootstrap.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
