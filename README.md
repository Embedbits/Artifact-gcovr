# gcovr – Artifact

Portable, self-contained distribution of **gcovr**, the tool that creates the coverage reports (text, HTML, Cobertura XML, JSON) from the data of gcov. This repository is consumed by the Embedbits Platform Artifact Handler to locate, download, verify, and configure gcovr in downstream embedded build tooling (coverage of the host unit tests and of the integration tests executed on the target) without depending on whatever is installed on the host machine.

gcovr is a Python application. The artifact is gcovr **frozen to a standalone application** (PyInstaller, built from the artifact `python`): it needs **no Python, no pip package and no other library of the system** – only the C library of the platform. gcov itself is not part of it, it belongs to the compiler (artifacts `gcc` and `gcc-arm-none-eabi`).

Each branch in this repository plays a distinct role, allowing precise version control and reproducible builds across projects.

---

## Repository contents

```
gcovr/
├── main branch
│   ├── README.md                 ← this file
│   └── ArtifactConfig.cmake      ← Artifact metadata template
│
├── Core branch
│   └── ArtifactConfig.cmake      ← Artifact metadata and initialization (GCOVR_EXECUTABLE)
│
└── Bin branch                    ← see "How binaries are published" below
    tags: Bin/<version>-<platform>, e.g. Bin/8.6.0-Unix
```

---

## Role in the platform

```
GitHub (Embedbits)
──────────────────────────────────────────────────────────
Artifact-gcovr
  main branch          →  README, ArtifactConfig.cmake template
  Core branch           →  CMake handler scripts
  Bin branch            →  anchor branch + per-version/platform tags
    Bin/8.6.0-Unix       →  GitHub Release: gcovr 8.6, Linux x86_64
    Bin/8.6.0-Win         →  GitHub Release: gcovr 8.6, Windows x86_64
    ...
```

The Platform Artifact Handler in downstream projects reads `ArtifactConfig.cmake` to determine which release to fetch, then downloads and verifies the appropriate binary archive from that tag.

---

## How binaries are published

There is no upstream binary of gcovr (it is distributed as a Python package only), so the packages are built by the pipeline `Gcovr-Importer` of the repository `Maintenance/Artifacts_Handler`:

1. `Gcovr_Build.sh` runs once per platform on a host of that platform (Windows x86_64, Linux x86_64): it installs gcovr and PyInstaller with the exact versions of `Scripts/Gcovr/constraints.txt` (wheels only) into a temporary virtual environment of the Python of the artifact `python`, freezes gcovr, **audits the dependencies** of every executable and library (a library of the system other than the C library fails the build), runs a **smoke test** of all report formats with the environment of the system only, creates `gcovr-<X.Y.Z>-<platform>.zip` + `.zip.hash` and tests the package extracted again.
2. `Gcovr_Importer.sh` publishes the packages of all platforms.

**GitHub** – the `Bin` branch only contains **empty commits** (anchors for tagging). Each `Bin/<version>-<platform>` tag points to a GitHub Release with the archive and its SHA-256 hash file as release assets:

```
Bin/8.6.0-Unix  (tag + GitHub Release)
├── gcovr-8.6.0-Unix.zip
└── gcovr-8.6.0-Unix.zip.hash
```

**Azure DevOps** – the same files are committed directly to the `Bin` branch (one commit per version and platform, tagged `Bin/<version>-<platform>`).

---

## ⚠️ Clone only the branch you need

This repository may contain **large binary data** across multiple versions. Always fetch a specific version's assets via its release rather than cloning the full `Bin` branch history.

```bash
gh release download Bin/8.6.0-Unix --repo Embedbits/Artifact-gcovr --pattern '*.zip'
```

---

## Supported platforms

| Platform code | Target | Requirements of the host |
|---|---|---|
| `Unix` | Linux x86_64 | glibc 2.25 or newer |
| `Win` | Windows x86_64 | Windows 10 or newer |

There is no macOS package.

---

## Included components

| Component | Description |
|---|---|
| `gcovr/gcovr(.exe)` | The executable of gcovr |
| `gcovr/_internal/` | Python runtime, gcovr, jinja2, lxml, Pygments and the other libraries of the application |

---

## Usage

The artifact is installed automatically during the **Artifacts setup phase**. `gcovr_ArtifactInit` resolves the executable for the current host platform and exposes it as `GCOVR_EXECUTABLE`; `gcovr_GetArtifactVersion` returns the version of gcovr in the format `X.Y.Z`.

---

## Versioning

Artifact versions correspond directly to **gcovr release versions** completed to `X.Y.Z`:

```
8.6.0, 8.7.0, ...
```

---

## Notes

- **No installation required** — the application is portable and self-contained; no Python of the system is required or affected.
- **Offline use** is supported once the artifact is cached locally.
- In **Azure DevOps pipelines**, caching the artifact folder is recommended to reduce build time.

---

## License

gcovr is distributed under the **BSD 3-Clause license**: [https://github.com/gcovr/gcovr/blob/main/LICENSE.txt](https://github.com/gcovr/gcovr/blob/main/LICENSE.txt). The application also contains Python (PSF License) and the Python packages jinja2, MarkupSafe, lxml, Pygments and colorlog under their own licenses (`_internal/*.dist-info`).

---

## Authors

- **Mr.Nobody** — [embedbits.com](https://embedbits.com)

Contributions are welcome! Please open a pull request.

---

## 🌐 Useful Links

- [gcovr Official Site](https://gcovr.com/)
- [gcovr on PyPI](https://pypi.org/project/gcovr/)
- [PyInstaller](https://pyinstaller.org/)
- [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/)
- [Embedbits Github](https://github.com/Embedbits)
- [CC BY-NC 4.0 License](https://creativecommons.org/licenses/by-nc/4.0/)
