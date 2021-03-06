<#
.Synopsis
	Invokes a file from the current editor.
	Author: Roman Kuzmin

.Description
	Saves the editor file and invokes it depending on its type.

	*.build.ps1, *.test.ps1 ~ the current task is invoked by
	Invoke-Build (https://github.com/nightroman/Invoke-Build)

	*.ps1 is invoked by powershell in a separate console.

	Markdown files are opened by Show-Markdown-.ps1

	If the file is .bat, .cmd, .fsx, .pl, etc. then some typical action is
	executed, mostly as demo, use your own invocation for practical tasks.

	As for the other files, the script simply calls Invoke-Item for them, i.e.
	starts a program associated with the file type.
#>

# Save the file and get the normalized path
$editor = $Psf.Editor()
$editor.Save()
$path = [System.IO.Path]::GetFullPath($editor.FileName)

# Extension
$ext = [IO.Path]::GetExtension($path)

### PowerShell.exe
if ($ext -eq '.ps1') {
	# Invoke-Build?
	if ($path -match '\.(?:build|test)\.ps1$') {
		$task = '.'
		$line = $editor.Caret.Y + 1
		foreach($t in (Invoke-Build ?? $path).Values) {
			if ($t.InvocationInfo.ScriptName -ne $path) {continue}
			if ($t.InvocationInfo.ScriptLineNumber -gt $line) {break}
			$task = $t.Name
		}
		$arg = "-NoExit -NoProfile -ExecutionPolicy Bypass Invoke-Build.ps1 '{0}' '{1}'" -f @(
			$task.Replace("'", "''").Replace('"', '\"')
			$path.Replace("'", "''")
		)
	}
	else {
		# sub-command?
		$root = [IO.Path]::GetDirectoryName($path)
		if ($root.ToLower().EndsWith('.ps1.commands')) {
			$arg = "-NoExit -ExecutionPolicy Bypass . '{0}' {1}" -f @(
				$root.Substring(0, $root.Length - 9).Replace("'", "''")
				[IO.Path]::GetFileNameWithoutExtension($path)
			)
		}
		# generic script
		else {
			$arg = "-NoExit -ExecutionPolicy Bypass . '$($path.Replace("'", "''"))'"
		}
	}
	Start-Process powershell.exe $arg
	return
}

$arg = "`"$path`""

### Markdown
if ('.text', '.md', '.markdown' -contains $ext) {
	Show-Markdown-.ps1
}

### cmd
elseif ('.bat', '.cmd' -contains $ext) {
	cmd /c start cmd /k $arg
}

### fsx
elseif ('.fsx' -eq $ext) {
	Start-Process fsx.exe ('--nologo', "--use:$arg")
}

### Perl
elseif ('.pl' -eq $ext) {
	cmd /c start cmd /k perl $arg
}

### Others
else {
	Invoke-Item -LiteralPath $path
}
