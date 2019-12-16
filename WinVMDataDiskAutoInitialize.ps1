# WinVMDataDiskAutoInitialize Powered by PowerShell
# Author: Archers Law <archerslaw@163.com>	
# Description: Auto diskpart tool for Windows OS	
# Github URL: https://github.com/archerslaw/diskpart-auto-tool

# Set Bypass ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

$diskpartCmd = 'LIST DISK'
$disks = $diskpartCmd | diskpart.exe

Write-Host "Print the disk list info:"
$disks

foreach ($line in $disks)
{
	if ($line -match 'Disk\s+(?<DiskNumber>\d+) | 磁盘\s+(?<DiskNumber>\d+)')
	{
		$diskNumber = $Matches.DiskNumber
		if ([int]$diskNumber -ge 1)
		{
			$diskpartCmd = "@
				SELECT DISK $diskNumber
				ONLINE DISK
				ATTRIBUTES DISK CLEAR READONLY
				EXIT
			@"
			Write-Host "Set ONLINE and clear READONLY with DataDisk:" $diskNumber
			$diskpartCmd | diskpart.exe | Out-Null
			Start-Sleep -Seconds 0.1
		}
		else
		{
			Write-Host "SystemDisk no need to set ONLINE and clear READONLY."
		}
	}
	else
	{
		Write-Host "This line has no any Disk info at all."
	}
}

$volumepartCmd = 'LIST VOLUME'
$volumes = $volumepartCmd | diskpart.exe

Write-Host "Print the volume list info:"
$volumes

foreach ($line in $volumes)
{
    if ($line -match 'Volume\s+(?<VolumeNumber>\d+) | 卷\s+(?<VolumeNumber>\d+)')
    {
        $volumeNumber = $Matches.VolumeNumber
		Write-Host "Print the extend Volume list info:" $volumeNumber

		if ([int]$volumeNumber -ge 2)
		{
		    $volumepartCmd = "@
				SELECT VOLUME $volumeNumber
				EXTEND NOERR
				EXIT
			@"
			Write-Host "Start to extend the DataDisk:" $volumeNumber
			$volumepartCmd | diskpart.exe | Out-Null
			
			Start-Sleep -Seconds 0.1
			Write-Host "Complete to extend the DataDisk:" $volumeNumber
		}
		else
		{
			Write-Host "SystemDisk no need to extend at all."
		}
	}
	else
	{
		Write-Host "This line has no any Volume info at all."
	}
}

$diskpartCmd = 'LIST DISK'
$disks = $diskpartCmd | diskpart.exe

Write-Host "Print the disk list info:"
$disks

foreach ($line in $disks)
{
    if ($line -match 'Disk\s+(?<DiskNumber>\d+)\s+(Online|Offline)\s+(?<Size>\d+)\s+GB\s+(?<Free>\d+)|磁盘\s+(?<DiskNumber>\d+)\s+(联机|脱机)\s+(?<Size>\d+)\s+GB\s+(?<Free>\d+)')
    {
        $nextDriveLetter = [char[]](67..90) | 
        Where-Object { (Get-WmiObject -Class Win32_LogicalDisk | 
		Select-Object -ExpandProperty DeviceID) -notcontains "$($_):" } | 
        Select-Object -First 1
		
        $diskNumber = $Matches.DiskNumber
		Write-Host "Print the initialize Disk info:" $diskNumber
		Write-Host "Print the NEXT Drive letter:" $nextDriveLetter
		$FreeSize = $Matches.Free
		Write-Host "Print the Disk free size:" $FreeSize
		
		if ([int]$diskNumber -ge 1)
		{
			if ([int]$FreeSize -gt 0)
			{
				$diskpartCmd = "@
					SELECT DISK $diskNumber
					CREATE PARTITION PRIMARY
					FORMAT FS=NTFS LABEL='DataDisk$diskNumber' QUICK
					ASSIGN LETTER=$nextDriveLetter
					EXIT
				@"
				Write-Host "Start to initialize the DataDisk:" $diskNumber
				$diskpartCmd | diskpart.exe | Out-Null
			
				Start-Sleep -Seconds 0.1
				Write-Host "Complete to initialize the DataDisk:" $diskNumber
			}
			else
			{
				Write-Host "DataDisk" $diskNumber "no need to initialize at all."
			}
		}
		else
		{
			Write-Host "SystemDisk no need to initialize at all."
		}
    }
	else
	{
		Write-Host "This line has no any Disk info at all."
	}
}

$diskpartCmd = 'LIST DISK'
$disks = $diskpartCmd | diskpart.exe
$volumepartCmd = 'LIST VOLUME'
$volumes = $volumepartCmd | diskpart.exe

Write-Host "Print the disk list info:"
$disks
Write-Host "Print the volume list info:"
$volumes
