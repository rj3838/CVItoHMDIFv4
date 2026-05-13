CVItoHMDIFv4 — README

Overview
This repository contains a Julia application that converts CVI survey grid data to HMDIF for eventual upload to a PMS. The current main entry point is CVItoHMDIF_v2.jl which launches a native file picker and processes one or more CVI grid files.

What’s in this repo
- CVItoHMDIF_v2.jl: main script (calls main() at the end)
- Helper .jl files included from the main script
- Project.toml and Manifest.toml: Julia environment files
- Sample CSV/GRD files for testing

Prerequisites
- Julia 1.9+ (1.10 recommended)
- macOS, Windows, or Linux
- Optional: IntelliJ IDEA with the Julia plugin if you want IDE integration

Quick start (command line)
1) Open a terminal at the project root (the folder containing Project.toml).
2) Run:

   julia --project=. -e "using Pkg; Pkg.instantiate(); include(\"CVItoHMDIF_v2.jl\")"

3) The program will print:
   CVI to HMDIF
   Select a CVI grid file to convert to HMDIF

4) A native file chooser will open. Select one or more CVI grid CSV files.
5) Ensure the sections file named "East Sussex Sections 2025.csv" exists in the project root (default expected by the code). Change the filename in CVItoHMDIF_v2.jl if your sections file differs.

Using with IntelliJ IDEA + Julia Plugin (optional)
- Install IntelliJ IDEA (Community or Ultimate).
- Install the "Julia" plugin (Settings/Preferences > Plugins > Marketplace).
- Open the project (File > Open… > select the CVItoHMDIFv4 folder).
- Configure Julia executable (Settings/Preferences > Languages & Frameworks > Julia, then set the path to your julia binary).
- Activate the project environment in the REPL:

  using Pkg
  Pkg.activate(".")
  Pkg.instantiate()

- Create a Run Configuration (Run > Edit Configurations… > Julia Application):
  - Script: CVItoHMDIF_v2.jl
  - Working directory: project root
  - Environment/Project: use the project root (or set JULIA_PROJECT=.)
- Run the configuration and follow the file chooser prompts.

Notes on dependencies and dialogs
- The project uses NativeFileDialog and Gtk to open a native file picker.
- On first run, Pkg.instantiate() may download binaries; allow it to finish.
- On macOS, ensure IntelliJ/Terminal has permission to access files (System Settings > Privacy & Security > Files and Folders).

Outputs
- The app writes progress to the console and produces CSV outputs in the project directory (e.g., debug_*.csv, merged_*.csv, survey_records.csv). File names depend on the data being processed.

Troubleshooting
- Packages not found: be sure you activated the environment (Pkg.activate(".")) and ran Pkg.instantiate().
- Native file dialog doesn’t appear: avoid headless sessions; ensure app permissions are granted.
- Different sections file: edit the section_file_name variable in CVItoHMDIF_v2.jl.

FAQ
Q: Where is the README?
A: You’re reading it. This file (README.md) is in the project root (CVItoHMDIFv4). If it appears empty in your viewer, try reopening or pulling the latest changes.

Q: What is the entry point?
A: CVItoHMDIF_v2.jl. It includes all helper modules and calls main() at the end.

Q: Can I bypass the file dialog and pass paths directly?
A: Yes—modify CVItoHMDIF_v2.jl to read from ARGS or to call your own function with explicit file paths.

Support
If you share your OS and Julia/IDE setup, we can provide tailored instructions or screenshots.