$ErrorActionPreference = "Stop"
$vmName = "Kali"
$isoPath = "$env:USERPROFILE\Downloads\kali-linux-2026.2-installer-amd64.iso"
$vhdxPath = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\Kali.vhdx"
$vhdxDir = Split-Path $vhdxPath -Parent

if (-not (Test-Path $vhdxDir)) { New-Item -ItemType Directory -Path $vhdxDir -Force | Out-Null }
if (-not (Test-Path $isoPath)) { Write-Host "ISO not found: $isoPath"; Read-Host; exit 1 }

$vsMan = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementService

# === 1. Create Default Switch (internal/NAT) ===
Write-Host "[1/4] Creating virtual switch..." -ForegroundColor Yellow
$sw = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualEthernetSwitch | Where-Object { $_.ElementName -eq "NanaBoxSwitch" }
if (-not $sw) {
    $swResult = Invoke-CimMethod -InputObject $vsMan -MethodName CreateSwitch -Arguments @{
        Name         = "NanaBoxSwitch"
        FriendlyName = "NanaBoxSwitch"
        IsInternal   = $true
        Notes        = ""
    }
    Write-Host "  Switch created. ReturnValue=$($swResult.ReturnValue)" -ForegroundColor Green
} else {
    Write-Host "  Switch already exists." -ForegroundColor Cyan
}

# === 2. Create VHDX ===
Write-Host "[2/4] Creating VHDX (60GB)..." -ForegroundColor Yellow
if (Test-Path $vhdxPath) {
    Write-Host "  VHDX exists." -ForegroundColor Cyan
} else {
    $imgMan = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_ImageManagementService
    $r = Invoke-CimMethod -InputObject $imgMan -MethodName CreateVirtualHardDisk -Arguments @{
        Path            = $vhdxPath
        MaxInternalSize = 64424509440
    }
    Write-Host "  VHDX created. ReturnValue=$($r.ReturnValue)" -ForegroundColor Green
}

# === 3. Create VM ===
Write-Host "[3/4] Creating VM..." -ForegroundColor Yellow
$existingVM = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_ComputerSystem | Where-Object { $_.ElementName -eq $vmName }
if ($existingVM) {
    Write-Host "  Removing old VM..." -ForegroundColor Cyan
    Invoke-CimMethod -InputObject $vsMan -MethodName DestroySystem -Arguments @{ ComputerSystem = $existingVM } | Out-Null
    Start-Sleep -Seconds 3
}

$r = Invoke-CimMethod -InputObject $vsMan -MethodName DefineSystem -Arguments @{
    Name                 = $vmName
    Generation           = 2
    VirtualSystemSubType = "Microsoft:Hyper-V:SubType:2"
}
if ($r.ReturnValue -ne 0) { Write-Host "DefineSystem failed: $($r.ReturnValue)"; Read-Host; exit 1 }
Write-Host "  VM defined." -ForegroundColor Green

$vm = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_ComputerSystem | Where-Object { $_.ElementName -eq $vmName }

# Memory: 4GB
$mem = Get-CimAssociatedInstance -InputObject $vm -ResultClassName Msvm_MemorySettingData
$mem.VirtualQuantity = 4096
$mem.DynamicMemoryEnabled = $true
Invoke-CimMethod -InputObject $vsMan -MethodName ModifySystemSettings -Arguments @{ SystemSettings = $mem.GetText(2) } | Out-Null
Write-Host "  Memory: 4GB" -ForegroundColor Green

# CPU: 2
$proc = Get-CimAssociatedInstance -InputObject $vm -ResultClassName Msvm_ProcessorSettingData
$proc.VirtualQuantity = 2
Invoke-CimMethod -InputObject $vsMan -MethodName ModifySystemSettings -Arguments @{ SystemSettings = $proc.GetText(2) } | Out-Null
Write-Host "  CPU: 2 vCPUs" -ForegroundColor Green

# Attach VHDX to SCSI controller
$scsi = Get-CimAssociatedInstance -InputObject $vm -ResultClassName Msvm_StorageAllocationSettingData | Where-Object { $_.ResourceSubType -eq "Microsoft:Hyper-V:Synthetic SCSI Controller" } | Select-Object -First 1
if ($scsi) {
    $diskXml = @"
<ResourceAllocationSettingData xmlns="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData">
  <InstanceID>Microsoft:KaliDisk</InstanceID>
  <ResourceType>31</ResourceType>
  <ResourceSubType>Microsoft:Hyper-V:Virtual Disk</ResourceSubType>
  <HostResource><Format>http://schemas.microsoft.com/wbem/wsman/1/disks</Format><Value>$vhdxPath</Value></HostResource>
  <Parent>$($scsi.InstanceID)</Parent>
</ResourceAllocationSettingData>
"@
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName AddResourceSettings -Arguments @{
        AffectedConfiguration = $vm.GetText(2)
        ResourceSettings      = @($diskXml)
    }
    Write-Host "  Disk attached. ReturnValue=$($r.ReturnValue)" -ForegroundColor Green
}

# Attach ISO to DVD drive
$dvd = Get-CimAssociatedInstance -InputObject $vm -ResultClassName Msvm_StorageAllocationSettingData | Where-Object { $_.ResourceSubType -eq "Microsoft:Hyper-V:Synthetic DVD Drive" } | Select-Object -First 1
if ($dvd) {
    $isoXml = @"
<ResourceAllocationSettingData xmlns="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData">
  <InstanceID>Microsoft:KaliISO</InstanceID>
  <ResourceType>31</ResourceType>
  <ResourceSubType>Microsoft:Hyper-V:Virtual CD/DVD Disk</ResourceSubType>
  <HostResource><Format>http://schemas.microsoft.com/wbem/wsman/1/isos</Format><Value>$isoPath</Value></HostResource>
  <Parent>$($dvd.InstanceID)</Parent>
</ResourceAllocationSettingData>
"@
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName AddResourceSettings -Arguments @{
        AffectedConfiguration = $vm.GetText(2)
        ResourceSettings      = @($isoXml)
    }
    Write-Host "  ISO attached. ReturnValue=$($r.ReturnValue)" -ForegroundColor Green
}

# === 4. Start VM ===
Write-Host "[4/4] Starting VM..." -ForegroundColor Yellow
$r = Invoke-CimMethod -InputObject $vm -MethodName RequestStateChange -Arguments @{ RequestedState = 2 }
Write-Host "  Start ReturnValue=$($r.ReturnValue)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Done. VM 'Kali' is starting. ===" -ForegroundColor Green
Write-Host "Open NanaBox to connect. Login: kali / kali" -ForegroundColor Cyan
Read-Host "Press Enter"
