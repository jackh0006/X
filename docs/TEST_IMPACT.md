# Test impact policy

The goal is to keep development fast without skipping security-critical work.
Ordinary feature updates run the affected suites plus their new tests; releases
run the full gate. A module-to-test map is maintained below.

| Changed area | Required checks |
|---|---|
| `app/lib/screens`, `app/lib/widgets` | `flutter analyze`, affected widget tests, new UI tests, screenshots if visible |
| `app/lib/settings.dart`, storage UI | widget tests, Linux launch, Android native compile |
| `core/src/format.rs` | all Rust tests, parser property tests, fuzz, compatibility fixtures |
| `core/src/crypto.rs`, `limits.rs` | full crypto suite, independent vectors, fuzz, cross-platform interop |
| `app/android/**`, `app/linux/**` | platform build, APK/DEB verification, integration test |
| Dependencies | `cargo audit`, `cargo deny`, full tests, both package builds |
| Docs only | link/format checks; no binary rebuild |
| Any release | full mandatory gate below |

## Mandatory release gate

1. 34+ Rust tests, fmt, clippy, audit, deny.
2. 15+ Flutter/native tests, analyze, coverage report.
3. Parser fuzz campaign.
4. Linux↔Android interoperability.
5. APK arm64/signature/permission/ABI verification.
6. DEB metadata/extraction/launch/install simulation.
7. Secret scan, CodeQL, dependency review, SBOM, checksums, provenance.
8. Screenshots when visible UI changed.
9. Publish the test report for the exact tagged commit.

## Latest tested release

`v1.1.1` — update this line and `docs/TEST_RESULTS.md` for every release.
