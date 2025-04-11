$pid_code_to_name = @{}

$pid_code_to_name["0104"] = "Calculated engine load [%]"
$pid_code_to_name["0105"] = "Engine coolant temperature [Â°C]"
$pid_code_to_name["010A"] = "Fuel pressure [kPa]"
$pid_code_to_name["010C"] = "Engine speed [RPM]"
$pid_code_to_name["0110"] = "Air flow rate [g/s]"
$pid_code_to_name["0111"] = "Throttle position [%]"
$pid_code_to_name["0123"] = "Fuel Rail Gauge Pressure [kPa]"
$pid_code_to_name["0133"] = "Absolute Barometric Pressure [kPa]"
$pid_code_to_name["013C"] = "Catalyst Temperature: Bank 1, Sensor 1 [Â°C]"
$pid_code_to_name["0143"] = "Absolute load value [%]"
$pid_code_to_name["0144"] = "Commanded Air-Fuel Equivalence Ratio"
$pid_code_to_name["0145"] = "Relative throttle position [%]"
$pid_code_to_name["0146"] = "Ambient air temperature [Â°C]"
$pid_code_to_name["0149"] = "Accelerator pedal position D [%]"
$pid_code_to_name["014A"] = "Accelerator pedal position E [%]"
$pid_code_to_name["0162"] = "Actual engine - percent torque [%]"
$pid_code_to_name["0163"] = "Engine reference torque [Nm]"
$pid_code_to_name["01A6"] = "Odometer [km]"


function Convert-Pid {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    return $pid_code_to_name[$Key]
}


function Convert-Value {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [int]$Raw
    )
    $value = $Raw
    if ($Key -eq "0104") {
        $value = [math]::Round(($Raw / 2.55), 2)
    } elseif ($Key -eq "0105" -or $Key -eq "0146") {
        $value = $Raw - 40
    } elseif ($Key -eq "010A") {
        $value = 3 * $Raw
    } elseif ($Key -eq "010C") {
        $value = $Raw -shr 2
    } elseif ($Key -eq "0110") {
        $value = $Raw / 100
    } elseif ($Key -eq "0111") {
        $value = [math]::Round((100 / 255 * $Raw), 2)
    } elseif ($Key -eq "0123") {
        $value = $Raw * 10
    } elseif ($Key -eq "013C") {
        $value = [math]::Round(($Raw / 10 - 40), 2)
    } elseif ($Key -eq "0143" -or $Key -eq "0145" -or $Key -eq "0149" -or $Key -eq "014A") {
        $value = [math]::Round((100 / 255 * $Raw), 2)
    } elseif ($Key -eq "0144") {
        $value = [math]::Round((2 / 65536 * $Raw), 2)
    } elseif ($Key -eq "0162") {
        $value = $Raw - 125
    } elseif ($Key -eq "01A6") {
        $value = "$($Raw.ToString().Substring(0, $($Raw.ToString().Length - 1))).$($Raw.ToString().Substring($($Raw.ToString().Length - 1)))"
    }
    return $value
}