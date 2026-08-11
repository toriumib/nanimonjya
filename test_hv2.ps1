$log = "$env:USERPROFILE\Desktop\hv_test_result.txt"
"=== Hyper-V WMI Test $(Get-Date) ===" | Out-File $log

$vsMan = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementService
"ManagementService: $($vsMan.SystemName)" | Out-File $log -Append

"Trying CreateSwitch..." | Out-File $log -Append
try {
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName CreateSwitch -Arguments @{
        Name = "TestSwitch"
        FriendlyName = "TestSwitch"
        IsInternal = $true
        Notes = ""
    } -ErrorAction Stop
    "CreateSwitch ReturnValue=$($r.ReturnValue)" | Out-File $log -Append
} catch {
    "CreateSwitch ERROR: $_" | Out-File $log -Append
}

"Trying DefineSystem..." | Out-File $log -Append
try {
    $r = Invoke-CimMethod -InputObject $vsMan -MethodName DefineSystem -Arguments @{
        Name = "TestVM"
        Generation = 2
        VirtualSystemSubType = "Microsoft:Hyper-V:SubType:2"
    } -ErrorAction Stop
    "DefineSystem ReturnValue=$($r.ReturnValue)" | Out-File $log -Append
    if ($r.ReturnValue -eq 0) {
        $vm = $r.ResultingSystem
        "VM created! Cleaning up..." | Out-File $log -Append
        Invoke-CimMethod -InputObject $vsMan -MethodName DestroySystem -Arguments @{ ComputerSystem = $vm } | Out-Null
    }
} catch {
    "DefineSystem ERROR: $_" | Out-File $log -Append
}

"Done." | Out-File $log -Append
