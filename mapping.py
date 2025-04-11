
pid_code_to_name = dict()

pid_code_to_name["0104"] = "Calculated engine load [%]"
pid_code_to_name["0105"] = "Engine coolant temperature [Â°C]"
pid_code_to_name["010A"] = "Fuel pressure [kPa]"
pid_code_to_name["010C"] = "Engine speed [RPM]"
pid_code_to_name["0110"] = "Air flow rate [g/s]"
pid_code_to_name["0111"] = "Throttle position [%]"
pid_code_to_name["0123"] = "Fuel Rail Gauge Pressure [kPa]"
pid_code_to_name["0133"] = "Absolute Barometric Pressure [kPa]"
pid_code_to_name["013C"] = "Catalyst Temperature: Bank 1, Sensor 1 [Â°C]"
pid_code_to_name["0143"] = "Absolute load value [%]"
pid_code_to_name["0144"] = "Commanded Air-Fuel Equivalence Ratio"
pid_code_to_name["0145"] = "Relative throttle position [%]"
pid_code_to_name["0146"] = "Ambient air temperature [Â°C]"
pid_code_to_name["0149"] = "Accelerator pedal position D [%]"
pid_code_to_name["014A"] = "Accelerator pedal position E [%]"
pid_code_to_name["0162"] = "Actual engine - percent torque [%]"
pid_code_to_name["0163"] = "Engine reference torque [Nm]"
pid_code_to_name["01A6"] = "Odometer [km]"


def convert_pid(key):
    return pid_code_to_name[key]


def convert_value(key, raw):
    value = raw
    if key == "0104":
        value = str(round(raw / 2.55, 2))
    elif key == "0105" or key == "0146":
        value = str(raw - 40)
    elif key == "010A":
        value = str(3 * raw)
    elif key == "010C":
        value = str(raw >> 2)
    elif key == "0110":
        value = str(raw / 100)
    elif key == "0111":
        value = str(100 / 255 * raw)
    elif key == "0123":
        value = str(raw * 10)
    elif key == "013C":
        value = str(raw / 10 - 40)
    elif key == "0143" or key == "0145" or key == "0149" or key == "014A":
        value = str(round(100 / 255 * raw, 2))
    elif key == "0144":
        value = str(round(2 / 65536 * raw, 2))
    elif key == "0162":
        value = str(raw - 125)
    elif key == "01A6":
        value = str(raw)[0:-1] + "." + str(raw)[-1]
    return value