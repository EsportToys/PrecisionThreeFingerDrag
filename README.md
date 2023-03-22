# PrecisionThreeFingerDrag

This simple AutoIt script uses the RawInput API to read `DIGITIZER - TOUCH PAD` input reports and the SendInput API to send mouse motion and clicks.

NOTE: only tested on Microsoft Surface touchpads, it currently assumes a hard-coded struct format that I reverse-engneered by experimenting with [RawInputViewer](https://github.com/EsportToys/RawInputViewer)

## Instructions

1. Download AutoIt from https://autoitscript.com
2. Run script with AutoIt by dragging `finger.au3` over onto AutoIt3_x64.exe

## Dependency

This does not use any UDFs, script and API calls are entirely self-contained. Only the AutoIt executable is needed.

## To-Do

- [ ] Add compatibility checks for present trackpads on startup (needs to report at least three fingers)
- [ ] Use `HidP-*` winapi calls to parse the raw data strings