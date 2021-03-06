
<#
.Synopsis
	Sets selected text in the editor, command line or dialog editbox.
	Author: Roman Kuzmin

.Description
	It changes the selected text in the current editor, command line or dialog
	edit box. Operations are defined by a single parameter.

.Example
	# Escape \ and " with \
	Set-Selection-.ps1 -Replace '([\\"])', '\$1'

	# Unescape \\ and \"
	Set-Selection-.ps1 -Replace '\\([\\"])', '$1'

	# Convert selected text to lower\upper case
	Set-Selection-.ps1 -ToLower
	Set-Selection-.ps1 -ToUpper
#>

param
(
	[object[]]
	# Replace: [0]: regex pattern, [1]: replacement string.
	$Replace
	,
	[switch]
	# Change selected text to lower case.
	$ToLower
	,
	[switch]
	# Change selected text to upper case.
	$ToUpper
)

# get selected text
$wt = $Far.Window.Kind
if ($wt -eq 'Editor') {
	$editor = $Far.Editor
	$text = $editor.GetSelectedText()
}
else {
	$line = $Far.Line
	$text = $line.SelectedText
}
if (!$text) { return }

# keep text length and change text
$length = $text.Length
if ($Replace) {
	$text = $text -replace $Replace
}
elseif ($ToLower) {
	$text = $text.ToLower()
}
elseif ($ToUpper) {
	$text = $text.ToUpper()
}

# set new text
if ($wt -eq 'Editor') {
	$editor.SetSelectedText($text)
}
else {
	$line.SelectedText = $text
}
