# Gaphor Chocolatey Package

This is the Chocolatey package for Gaphor, the simple modeling tool.

## What is Gaphor?

Gaphor is a UML, SysML, RAAML, and C4 modeling application. It is designed to be easy to use, while still being powerful. Gaphor implements a fully-compliant UML 2 data model, so it is much more than a picture drawing tool.

For more information, please visit the official Gaphor website: [https://gaphor.org/](https://gaphor.org/)

## Installation

You can install this package using Chocolatey:

```powershell
choco install gaphor
```

## Package Features

*   **Downloads from Official Source**: This package downloads the official 64-bit installer directly from the Gaphor GitHub releases page at runtime.
*   **Checksum Verification**: The integrity of the downloaded installer is verified using a SHA256 checksum.
*   **Dependency Management**: The package automatically installs required dependencies, such as `graphviz`.
*   **Robust Installation & Upgrades**: The package includes logic to gracefully shut down any running Gaphor instances before performing an upgrade or uninstallation, preventing file lock issues.
*   **Silent Installation**: The installation is performed silently with no user interaction required.

## Source Code

*   **Gaphor Application**: [https://github.com/gaphor/gaphor](https://github.com/gaphor/gaphor)
*   **Chocolatey Package**: [https://github.com/valtoni/choco-gaphor](https://github.com/valtoni/choco-gaphor)

This package is maintained by the community. If you find an issue with the package, please report it on the package's GitHub repository.