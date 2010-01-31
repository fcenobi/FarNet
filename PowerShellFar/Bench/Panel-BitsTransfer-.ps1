
<#
.SYNOPSIS
	Starts or manages file transfer jobs in a panel.
	Author: Roman Kuzmin

.DESCRIPTION
	Without parameters it opens the panel with file transfer jobs where you can
	operate on them. It monitors all existing jobs, even created in another
	PowerShell session or started in previous Windows sessions.

	With parameters it starts a new job and after that opens the panel, if it
	is not yet opened, or reuses an opened one.

	Important: when a job state is "Transferred" files are not yet ready, you
	have to "Complete" the job to make files saved.

	PANEL ACTIONS

	[Enter]
	Opens the current job menu. Commands:
	- Complete - Save transferred files and clear the job.
	- Suspend - Suspend the job, use Resume after this.
	- Resume - Resume the suspended job.
	- Clear - Clear the job and temporary files.
	Note: commands may take some time in the background before you can see
	changes in the panel.

	[Delete]
	Clears the selected jobs and their temporary files.

	Others keys are standard object panel keys, for example [CtrlPgDn] opens
	member panel, the job details in this case, [CtrlR] refreshes job list or
	job property panel, etc.

	Far and job data map:
	- Name - job.DisplayName
	- Description - job.JobState
	- Size - Transfer percentage
	- Created - job.CreationTime
	- Modified - job.ModificationTime
	- Accessed - job.TransferCompletionTime
	Use [CtrlPgDn] to see all job properties.

	SEE ALSO

	Import-Module BitsTransfer
	Get-Command *-BitsTransfer

.EXAMPLE
	# Open file transfer jobs panel if not yet
	Panel-BitsTransfer-

	# Start MyJob to transfer selected files from the active panel to passive
	Panel-BitsTransfer- -DisplayName MyJob -Auto

	# Transfer File1 from Web server
	Panel-BitsTransfer- -Source http://server/File1 -Destination C:\File1
#>

[CmdletBinding()]
param
(
	[string[]]
	# Names of the files to transfer at the server. The names are paired with the corresponding client file names by indices.
	$Source,

	[string[]]
	# Existing destination directory or names of the files to transfer at the client. The names are paired with the corresponding server file names by indices.
	$Destination,

	[string]
	# Display name of the transfer job. Default: current date and time.
	$DisplayName = ([DateTime]::Now.ToString('s')),

	[switch]
	# Starts a new job where the server files are the selected files on the active panel and the destination directory is the passive panel path.
	$Auto
)

Set-StrictMode -Version 2
Import-Module BitsTransfer

### Resolve -Auto
if ($Auto) {
	$Source = Get-FarPath -Selected
	$Destination = Get-FarPath -Selected -Mirror
}

### Start transfer
if ($Source -and $Destination) {
	if ($Source.Count -ne $Destination.Count) {
		$Far.Message("Different server and client file numbers.")
		return
	}
	if ($Source.Count -eq 1) {
		$msg = "Transfer`n$($Source[0])`nto`n$($Destination[0])"
	}
	else {
		$msg = "Transfer $($Source.Count) files"
	}
	if ($Far.Message($msg, "File transfer job: $DisplayName", 'OkCancel') -ne 0) {
		return
	}
	$null = Start-BitsTransfer -DisplayName $DisplayName -Source $Source -Destination $Destination -Asynchronous
}

### Check opened
[Guid]$id = 'edd13d45-281a-460b-8ab1-42f587128c67'
$p = $Far.FindPanel($id)
if ($p) { return }

### Create panel
$p = New-FarUserPanel
$p.Columns = @(
	@{ Type = 'N'; Expression = 'DisplayName' }
	@{ Type = 'S'; Label = '% done'; Expression = { if ($_.BytesTotal) { 100 * $_.BytesTransferred / $_.BytesTotal } else { 100 } } }
	@{ Type = 'O'; Label = 'State'; Width = 15; Expression = 'JobState' }
	@{ Type = 'DC'; Label = 'Created'; Expression = 'CreationTime' }
)

### Panel jobs
$p.SetGetObjects({
	Get-BitsTransfer -ErrorAction 0
})

### Delete jobs
$p.SetDelete({
	if ($Far.Message('Remove selected transfer jobs?', 'Remove', 'OkCancel') -ne 0) { return }
	foreach($f in $_.Files) {
		Remove-BitsTransfer -BitsJob $f.Data
	}
})

### Open a job
$p.SetOpen({
	$job = $_.File.Data

	New-FarMenu -Show "Job: $($job.DisplayName)" $(
		if ($job.JobState -eq 'Transferred') {
			New-FarItem 'Complete' {
				Complete-BitsTransfer -BitsJob $job -Confirm
			}
		}
		if ($job.JobState -eq 'Transferring') {
			New-FarItem 'Suspend' {
				Suspend-BitsTransfer -BitsJob $job -Confirm
			}
		}
		if ($job.JobState -eq 'Suspended') {
			New-FarItem 'Resume' {
				Resume-BitsTransfer -BitsJob $job -Confirm -Asynchronous
			}
		}
		New-FarItem 'Remove' {
			Remove-BitsTransfer -BitsJob $job -Confirm
		}
	)

	$this.Panel.Update($true)
	$this.Panel.Redraw()
})

# Go
Start-FarPanel $p -TypeId $id -Title 'BITS Jobs' -DataId 'JobId' -IdleUpdate
