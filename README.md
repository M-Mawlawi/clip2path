# clip2path

**Take a screenshot, paste a file path.** A tiny Windows clipboard watcher that saves every
screenshot you copy to a PNG file and puts that file's path on the clipboard *next to* the image.

So after `Win + Shift + S`:

- `Ctrl + V` in a **terminal, text field, or chat box** → pastes `C:\Users\you\AppData\Local\clip2path\snip_20261015_120000_123.png`
- `Ctrl + V` in **Paint, Word, Slack, Figma** → pastes the image, exactly as before

Both formats live in the *same* clipboard entry, so every app just picks the one it understands.
Nothing to click, no extra window, no tray icon.

## Why

Plenty of tools accept an image only as a *path* — CLI programs, terminal-based AI agents
(Claude Code, Codex, Aider, Gemini CLI, …), `ffmpeg`, Python one-liners, Git commit attachments,
Markdown editors, upload prompts. Windows screenshots, meanwhile, live only in the clipboard as
raw bitmap data, so there is no path to give them. The usual workaround is to open Snipping Tool,
save as…, pick a folder, invent a filename, then type that path out.

clip2path removes that loop. Screenshot → `Ctrl + V`. The path is already there.

## Requirements

- Windows (tested on Windows 10 and 11)
- Windows PowerShell 5.1 (preinstalled) or PowerShell 7+

No installer, no dependencies, no admin rights.

## Install

```powershell
git clone https://github.com/<you>/clip2path.git C:\tools\clip2path
```

Then start it:

```powershell
powershell -NoProfile -STA -ExecutionPolicy Bypass -File C:\tools\clip2path\clip-to-path.ps1
```

That window must stay open. To run it invisibly instead, double-click
**`start-clip-to-path.vbs`** — same thing, no console window.

### Start it automatically at login

1. Right-click `start-clip-to-path.vbs` → **Create shortcut**
2. Press `Win + R`, type `shell:startup`, press Enter
3. Drop the shortcut in that folder

Or in one line:

```powershell
$s = (New-Object -ComObject WScript.Shell).CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\clip2path.lnk")
$s.TargetPath = "C:\tools\clip2path\start-clip-to-path.vbs"; $s.Save()
```

## Usage

1. Take a screenshot: `Win + Shift + S`, PrtScn, Greenshot, ShareX — anything that copies an
   image to the clipboard. Copying an image file's *content* from an app works too.
2. Paste where you need it.

Example, pasting straight into a terminal:

```
$ magick "C:\Users\you\AppData\Local\clip2path\snip_20261015_120000_123.png" -resize 50% small.png
         ^ this whole path came from Ctrl+V
```

## Options

| Option | Default | What it does |
| --- | --- | --- |
| `-SaveDir <path>` | `%LOCALAPPDATA%\clip2path` | Where the PNGs are written |
| `-Wsl` | off | Emit `/mnt/c/...` paths instead of `C:\...`, for tools running inside WSL |
| `-KeepDays <n>` | `7` | On startup, delete saved snips older than *n* days. `0` keeps everything |

```powershell
# WSL-style paths, keep a month of history, store snips in the project
powershell -NoProfile -STA -ExecutionPolicy Bypass -File .\clip-to-path.ps1 -Wsl -KeepDays 30 -SaveDir D:\snips
```

To pass options to the hidden launcher, edit the `-File` line in `start-clip-to-path.vbs` and
append them after the `.ps1` path.

## How it works

The script polls `GetClipboardSequenceNumber()` (a cheap user32 counter that changes whenever the
clipboard does) about twice a second. On a change it checks whether the clipboard holds an image
and no text. If so it saves the bitmap as PNG, then re-publishes a single `DataObject` carrying
*both* the original image and the path as `CF_UNICODETEXT`.

Paths containing spaces are quoted, so they survive being pasted into a shell.

Roughly 60 lines of PowerShell, all in [`clip-to-path.ps1`](clip-to-path.ps1) — worth a read
before you run it.

## Notes and limits

- **Images that arrive with text are skipped.** Copying a cell range in Excel, or an image with a
  caption from a browser, puts both formats on the clipboard; clip2path leaves those alone rather
  than overwrite the text you probably wanted. This is also how it ignores its own output.
- **PNG only**, at the resolution the source app put on the clipboard.
- **Polling, not events.** ~0% CPU at idle, but a screenshot taken and pasted within the same
  ~400 ms may miss the rewrite. Paste again and it's there.
- **Clipboard managers** that aggressively rewrite entries can fight over the clipboard. If
  pastes come out as the image only, that's usually the cause.
- Old snips are pruned only at startup, so a process left running for weeks keeps growing.
  `-KeepDays` applies on the next launch.
- Windows-only by design: it talks to the Win32 clipboard directly.

## Uninstall

Close the PowerShell process (or the hidden `powershell.exe` in Task Manager), delete the
startup shortcut, delete the folder, and remove `%LOCALAPPDATA%\clip2path` if you don't want the
saved screenshots.

## License

[MIT](LICENSE)
