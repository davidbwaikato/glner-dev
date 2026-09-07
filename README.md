# glner-dev

Portable development-language provisioning for `glner-workbench`.

This repository is intended to be checked out as the `dev/` Git submodule of the
main GLNER Workbench repository. It follows the same general pattern as the
`zork-dev` and `malleable-ebook-dev` helper repositories: pinned language
runtimes live below `prog-langs/`, downloads and expanded installations are
project-local, and no administrator/root access is required.

There is deliberately no `cli-tools/` directory at present because the GLNER
Workbench does not currently need a separately provisioned CLI toolchain.

## Pinned versions

- CPython **3.11.16**, from Astral's `python-build-standalone` release
  **20260901** (`install_only_stripped`).
- Node.js **22.23.2**.

Python 3.11 matches the workbench's current `requires-python >=3.11` and Ruff
`py311` target.

Node 22 is intentional. Vite 7 requires Node 20.19+ or 22.12+, so 22.23.2 is
comfortably new enough. It also has an `x64-glibc-217` build from the Node.js
unofficial-builds project, which allows this dev environment to run on older
x86-64 Linux hosts where the official current Node binaries require a newer
glibc. On modern Linux, macOS, and Windows the script downloads the official
Node.js distribution.

## Repository layout

```text
glner-dev/
├── README.md
├── versions.env
├── DOWNLOAD-DEV-TOOLS-ALL.sh
├── GET-DEV-TOOLS-ALL.sh
├── SETUP.bash
└── prog-langs/
    ├── _common.bash
    ├── DOWNLOAD-PYTHON.sh
    ├── INSTALL-PYTHON.sh
    ├── ACTIVATE-PYTHON.bash
    ├── DOWNLOAD-NODEJS.sh
    ├── INSTALL-NODEJS.sh
    ├── ACTIVATE-NODEJS.bash
    ├── downloads/             # cached archives; gitignored
    ├── installed/             # expanded runtimes; gitignored
    └── python3-for-glner/     # project virtualenv; gitignored
```

## Add to `glner-workbench`

From the root of the main repository:

```bash
git submodule add https://github.com/davidbwaikato/glner-dev.git dev
git submodule update --init --recursive
```

For a clone that already declares the submodule:

```bash
git submodule update --init --recursive
```

## First-time setup

From the `glner-workbench` root:

```bash
./dev/GET-DEV-TOOLS-ALL.sh
source ./dev/SETUP.bash
```

Then verify:

```bash
python --version
node --version
npm --version
```

The prompt will normally show the Python virtual environment name
`python3-for-glner` after activation.

`SETUP.bash` is safe to source repeatedly in the same shell. If the expected
`python3-for-glner` virtual environment is already active, it is left in place rather
than being activated again. If a different virtual environment is active, the GLNER
environment is activated in its place. The Node.js runtime directory is likewise added
to `PATH` only once.

### Download without installing

If you want to cache the binary archives first:

```bash
./dev/DOWNLOAD-DEV-TOOLS-ALL.sh
```

The archives are retained under:

```text
dev/prog-langs/downloads/
```

Subsequent runs reuse them. This also makes it straightforward to preserve a
particular binary distribution in the `glner-dev` Git repository if desired.
The directory is ignored by default; explicitly add a chosen archive with
`git add -f` if you decide to preserve it in Git.

### Show the selected download URLs

No files are downloaded with:

```bash
./dev/DOWNLOAD-DEV-TOOLS-ALL.sh --dry-run
```

## Installing GLNER Workbench dependencies

After activating the environment, install whichever GLNER extras are needed.
For the current web annotator and Papers Past browser transport, for example:

```bash
python -m pip install -e ".[dev,annotator,paperspast-browser]"
python -m playwright install chromium
```

Build the React frontend with the project-local Node.js:

```bash
cd web/annotator
npm install
npm run build
cd ../..
```

Once `web/annotator/dist/` exists, the FastAPI server can serve the built UI;
Node does not have to remain running on the server.

## Cross-platform behaviour

The scripts are written for Bash and support:

- Linux x86-64 and ARM64;
- macOS Intel and Apple Silicon;
- Windows x86-64 and ARM64 when run under Git Bash/MSYS2/Cygwin-style Bash.

For Python, the platform-specific `python-build-standalone` archive is selected
automatically. The baseline GNU/Linux builds are designed for broad portability and
currently target glibc 2.17 as their minimum for the common x86-64 target.

For Node.js:

- modern glibc Linux uses the official Node binary;
- Linux x86-64 with glibc older than 2.28 uses the Node unofficial
  `linux-x64-glibc-217` build;
- musl Linux uses the corresponding unofficial musl build;
- macOS and Windows use official Node distributions.

On Windows, `.zip` extraction uses `unzip` when available and falls back to
PowerShell `Expand-Archive` under Git Bash.

For troubleshooting or reproducible platform tests, `GLNER_DEV_OS_OVERRIDE`,
`GLNER_DEV_ARCH_OVERRIDE`, `GLNER_DEV_LIBC_OVERRIDE`, and
`GLNER_DEV_GLIBC_OVERRIDE` can override auto-detection.

## Caching / idempotence

The setup is deliberately restartable:

- a valid cached Python archive is not downloaded again;
- a matching expanded Python runtime is not unpacked again;
- an existing `python3-for-glner` virtualenv using the pinned Python is reused;
- a cached Node archive and checksum manifest are reused;
- a matching Node installation is reused.

Changing a pin in `versions.env` causes a new platform/version-specific runtime
to be installed without modifying the operating system's Python or Node.js.

## Bootstrap requirements

Only basic tools normally already present on the target environments are used:
Bash, `tar`, and either `curl` or `wget`. Windows Node extraction additionally
uses `unzip` or PowerShell. SHA-256 verification for Node uses `sha256sum`,
`shasum`, or `certutil` when available.
