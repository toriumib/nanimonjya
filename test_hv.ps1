Write-Host "=== Hyper-V WMI Test ==="

# Test 1: Can we access management service?
$vsMan = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementService
Write-Host "ManagementService: $($vsMan.SystemName)"

# Test 2: Can we create a switch?
Write-Host "`nTrying CreateSwitch..."
try {
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName CreateSwitch -Arguments @{
        Name = "TestSwitch"
        FriendlyName = "TestSwitch"
        IsInternal = $true
        Notes = ""
    } -ErrorAction Stop
    Write-Host "CreateSwitch ReturnValue=$($r.ReturnValue)"
} catch {
    Write-Host "CreateSwitch ERROR: $_"
}

# Test 3: Can we define a system?
Write-Host "`nTrying DefineSystem..."
try {
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName DefineSystem -Arguments @{
        Name = "TestVM"
        Generation = 2
        VirtualSystemSubType = "Microsoft:Hyper-V:SubType:2"
    } -ErrorAction Stop
    Write-Host "DefineSystem ReturnValue=$($r.ReturnValue)"
    if ($r.ReturnValue -eq 0) {
        $vm = $r.ResultingSystem
        Write-Host "VM created! Cleaning up..."
        Invoke-CimMethod -InputObject $vsMan -MethodName DestroySystem -Arguments @{ ComputerSystem = $vm } | Out-Null
    }
} catch {
    Write-Host "DefineSystem ERROR: $_"
}

Read-Host "Press Enter"
