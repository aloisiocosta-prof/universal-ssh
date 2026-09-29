"""Contract tests for the Pages build and tagged release workflow."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from release_contract import expected_release_tag, validate_pages_html, validate_release_tag


class ReleaseContractTest(unittest.TestCase):
    def test_pubspec_build_metadata_does_not_leak_into_git_tag(self):
        self.assertEqual(
            expected_release_tag("name: universal_ssh\nversion: 0.1.0+7\n"),
            "v0.1.0",
        )

    def test_tag_must_exactly_match_semver_from_pubspec(self):
        validate_release_tag("v0.1.0", "name: universal_ssh\nversion: 0.1.0+7\n")
        with self.assertRaisesRegex(ValueError, "must match"):
            validate_release_tag("v0.1.1", "version: 0.1.0+7\n")

    def test_tag_rejects_malformed_version(self):
        with self.assertRaisesRegex(ValueError, "SemVer"):
            expected_release_tag("version: 0.1\n")

    def test_pages_html_requires_repository_base_and_flutter_bootstrap(self):
        validate_pages_html(
            '<base href="/universal-ssh/"><script src="flutter_bootstrap.js"></script>',
            "/universal-ssh/",
        )

    def test_pages_html_rejects_wrong_repository_base(self):
        with self.assertRaisesRegex(ValueError, "base href"):
            validate_pages_html(
                '<base href="/"><script src="flutter_bootstrap.js"></script>',
                "/universal-ssh/",
            )

    def test_pages_html_requires_bootstrap(self):
        with self.assertRaisesRegex(ValueError, "flutter_bootstrap.js"):
            validate_pages_html('<base href="/universal-ssh/">', "/universal-ssh/")


if __name__ == "__main__":
    unittest.main()
