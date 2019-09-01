$volumepartCmd = 'LIST VOLUME'
$volumes = $volumepartCmd | diskpart.exe
Write-Host "Print the volume list info:" $volumes
foreach ($line in $volumes)
{
    if ($line -match 'Volume (?<VolumeNumber>\d) | 卷 (?<VolumeNumber>\d)')
    {
        $volumeNumber = $Matches.VolumeNumber
		Write-Host "Print the extend Disk info:" $volumeNumber
		if ([int]$volumeNumber -ge 2)
		{
		    $volumepartCmd = "@
				SELECT VOLUME $volumeNumber
				EXTEND NOERR
				EXIT
            @"
			Write-Host "Start to extend the DataDisk:" $volumeNumber
		    $volumepartCmd | diskpart.exe | Out-Null
			Start-Sleep -Seconds 1
			Write-Host "Complete to extend the DataDisk:" $volumeNumber
		}
		else
		{
			Write-Host "SystemDisk no need to extend at all."
		}
	}
	else
	{
		Write-Host "This line has no any DataDisk need to extend at all."
	}
}

$diskpartCmd = 'LIST DISK'
$disks = $diskpartCmd | diskpart.exe
Write-Host "Print the disk list info:" $disks
foreach ($line in $disks)
{
    if ($line -match 'Disk (?<DiskNumber>\d) \s+(Online|Offline)\s | 
	磁盘 (?<DiskNumber>\d) \s+(联机|脱机)\s')
    {
        $nextDriveLetter = [char[]](67..90) | 
        Where-Object { (Get-WmiObject -Class Win32_LogicalDisk | 
				Select-Object -ExpandProperty DeviceID) -notcontains "$($_):" } | 
        Select-Object -First 1
        $diskNumber = $Matches.DiskNumber
		Write-Host "Print the initialize Disk info:" $diskNumber
		if ([int]$diskNumber -ge 1)
		{
			$diskpartCmd = "@
				SELECT DISK $diskNumber
				ATTRIBUTES DISK CLEAR READONLY
				ONLINE DISK
				CREATE PARTITION PRIMARY
				EXIT
			@"
			Write-Host "Start to initialize the DataDisk:" $diskNumber
		    $diskpartCmd | diskpart.exe | Out-Null
			Start-Sleep -Seconds 1
			cmd.exe /c "echo Y | FORMAT $($nextDriveLetter): /Q /V:DataDisk$diskNumber"
			if ($?)
			{
				Write-Host "Complete to initialize the DataDisk:" $diskNumber
			}
			else
			{
				Write-Host "DataDisk" $diskNumber "is no need to initialize."
			}
		}
		else
		{
			Write-Host "SystemDisk no need to initialize at all."
		}
    }
	else
	{
		Write-Host "This line has no any DataDisk need to initialize at all."
	}
}
