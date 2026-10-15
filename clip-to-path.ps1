# clip-to-path.ps1
# Watches the clipboard. When an image shows up (e.g. from Snipping Tool / Win+Shift+S),
# it saves it as PNG and adds the file path as text to the SAME clipboard entry.
# Result: Ctrl+V in a terminal or any text field pastes the path;
#         Ctrl+V in Paint/Word/Slack still pastes the image itself.
#
# Usage:  powershell -NoProfile -STA -ExecutionPolicy Bypass -File clip-to-path.ps1 [options]
#   -SaveDir   where to store the PNGs (default: %LOCALAPPDATA%\clip2path)
#   -Wsl       paste paths as /mnt/c/... (for tools running inside WSL)
#   -KeepDays  delete saved snips older than this many days on startup (0 = keep forever)

param(
    [string]$SaveDir = "$env:LOCALAPPDATA\clip2path",
    [switch]$Wsl,
    [int]$KeepDays = 7
)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System.Runtime.InteropServices;
public static class ClipSeq {
    [DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();
}
"@

New-Item -ItemType Directory -Force -Path $SaveDir | Out-Null
if ($KeepDays -gt 0) {
    Get-ChildItem $SaveDir -Filter *.png -ErrorAction SilentlyContinue |
        Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) |
        Remove-Item -ErrorAction SilentlyContinue
}

$lastSeq = [ClipSeq]::GetClipboardSequenceNumber()

while ($true) {
    Start-Sleep -Milliseconds 400
    $seq = [ClipSeq]::GetClipboardSequenceNumber()
    if ($seq -eq $lastSeq) { continue }
    $lastSeq = $seq

    try {
        if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { continue }
        # Skip if the clipboard already has text (our own entry, or e.g. Excel cells)
        if ([System.Windows.Forms.Clipboard]::ContainsText()) { continue }

        $img  = [System.Windows.Forms.Clipboard]::GetImage()
        $file = Join-Path $SaveDir ("snip_{0:yyyyMMdd_HHmmss_fff}.png" -f (Get-Date))
        $img.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)

        if ($Wsl) {
            $path = '/mnt/' + $file.Substring(0,1).ToLower() + ($file.Substring(2) -replace '\\','/')
        } else {
            $path = $file
        }
        if ($path -match ' ') { $path = '"' + $path + '"' }

        $data = New-Object System.Windows.Forms.DataObject
        $data.SetImage($img)
        $data.SetText($path)
        [System.Windows.Forms.Clipboard]::SetDataObject($data, $true)
        $img.Dispose()

        # Don't react to our own clipboard change
        $lastSeq = [ClipSeq]::GetClipboardSequenceNumber()
    } catch {
        # Clipboard was busy/locked - try again on the next change
    }
}
