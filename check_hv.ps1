$vms = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_ComputerSystem
Write-Host "Found $($vms.Count) VM(s):"
foreach ($vm in $vms) {
    Write-Host "  $($vm.ElementName) - EnabledState: $($vm.EnabledState)"
}
Write-Host "---"
$switches = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualEthernetSwitch
Write-Host "Found $($switches.Count) switch(es):"
foreach ($s in $switches) {
    Write-Host "  $($s.ElementName)"
}
Read-Host "Press Enter"
