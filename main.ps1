# Requires the PySerial library to be installed in Python if you want to interact with serial ports
# You'll need to have Python installed and then run: pip install pyserial

# Import necessary modules (you might need to adapt these based on your system)
# PowerShell doesn't directly use Python libraries, so we'll try to achieve similar functionality
# Note: The 'os.system' calls for Bluetooth might need to be handled differently in PowerShell
#       depending on your operating system and Bluetooth adapter.

# Constant values
$code_list = @('0104', '0105', '010A', '010C', '0110', '0111', '0123', '0133', '013C', '0143', '0144', '0145', '0146',
             '0149', '014A', '0162', '0163', '01A6')
$safety_counter = 100

# Function to send PID to serial port, read response and handle result
function Query-SerialPort {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.Ports.SerialPort]$SerialPort,
        [Parameter(Mandatory=$true)]
        [string]$Code
    )

    $SerialPort.Write("$Code`r")
    $safety = 0
    $running = $true
    $trigger = 0
    $full_frame = [System.Collections.ArrayList]::new()

    while ($running) {
        $safety++
        # Read response (read one byte at a time)
        try {
            if ($SerialPort.BytesToRead -gt 0) {
                $responseByte = $SerialPort.ReadByte()
                [void]$full_frame.Add($responseByte)

                # Analyse response to look for EOF "\r\r>" (byte values 13 13 62)
                if ($responseByte -eq 13) {
                    $trigger++
                } elseif ($responseByte -eq 62 -and $trigger -eq 2) {
                    $running = $false
                } else {
                    $trigger = 0
                }
            }
            Start-Sleep -Milliseconds 10 # Add a small delay to avoid busy-waiting
        }
        catch {
            Write-Error "Error reading from serial port: $($_.Exception.Message)"
            $running = $false
            return $null # Or some indication of error
        }

        # Safety catch to avoid blockages
        if ($safety -eq $safety_counter) {
            $running = $false
        }
    }

    # Convert the ArrayList of bytes back to a byte array
    if ($full_frame.Count -gt 0) {
        return [byte[]]$full_frame
    } else {
        return $null
    }
}

# Function to format and print a human-readable presentation of the fetched data
function Format-Output {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [string]$Value
    )

    $full_text = ""
    # Check if the PID's text description has [unit of measure]
    if ($Key -like "*[*") {
        $startIndex = $Key.IndexOf('[')
        $textPart = ($Key.Substring(0, $startIndex)).Trim()
        $unitPart = ($Key.Substring($startIndex)).Trim()
        $full_text = "$textPart: $Value"
        if ($Value -ne "NO DATA" -and $Value -ne "CAN ERROR") {
            $full_text += " $unitPart"
        }
    } else {
        $full_text = "$($Key.Trim()): $($Value.Trim())"
    }
    return $full_text
}

    # Initialise the serial connection instance
    try {
        $portName = "/dev/rfcomm0" 
        $ser = New-Object System.IO.Ports.SerialPort
        $ser.PortName = $portName
        $ser.BaudRate = 115200
        $ser.Parity = [System.IO.Ports.Parity]::None
        $ser.StopBits = [System.IO.Ports.StopBits]::One
        $ser.DataBits = 8
        $ser.ReadTimeout = 300 # Timeout in milliseconds (0.3 seconds)

        # Open the serial communication
        $ser.Open()
    }
    catch {
        Write-Error "Error opening serial port '$portName': $($_.Exception.Message)"
        if ($ser -ne $null -and $ser.IsOpen) {
            $ser.Close()
        }
        exit
    }

    # Declaration of variables
    $run = $true
    $index = 0
    $full_response = @{}
    $previous_full_response = @{}

    # Main loop
    while ($run) {
        # Set the PID to query
        $code = $code_list[$index]

        # Query and get response
        $responseBytes = Query-SerialPort -SerialPort $ser -Code $code

        # Analyse response
        if ($responseBytes -eq $null -or ($responseBytes -like "*NO DATA*" -or $responseBytes -like "*CAN ERROR*")) {
            if ($previous_full_response.ContainsKey($code)) {
                $full_response[$code] = $previous_full_response[$code]
            } else {
                $responseString = [System.Text.Encoding]::ASCII.GetString($responseBytes)
                $full_response[$code] = $responseString.Replace("bytearray(b'", "").Replace("')", "")
            }
        } else {
            try {
                # Convert the relevant part of the byte array to a hexadecimal string and then to an integer
                if ($responseBytes.Count -ge 15) { # Check if the response is long enough
                    $hexString = ""
                    for ($i = 11; $i -lt ($responseBytes.Count - 4); $i++) {
                        $hexString += $responseBytes[$i].ToString("X2")
                    }
                    if ($hexString) {
                        $full_response[$code] = [int]::Parse($hexString, [System.Globalization.NumberStyles]::HexNumber)
                    } else {
                        $responseString = [System.Text.Encoding]::ASCII.GetString($responseBytes)
                        $full_response[$code] = $responseString.Replace("bytearray(b'", "").Replace("')", "")
                    }
                } else {
                    $responseString = [System.Text.Encoding]::ASCII.GetString($responseBytes)
                    $full_response[$code] = $responseString.Replace("bytearray(b'", "").Replace("')", "")
                }
            }
            catch {
                # Save data as is, if it cannot be converted to Integer
                $responseString = [System.Text.Encoding]::ASCII.GetString($responseBytes)
                $full_response[$code] = $responseString.Replace("bytearray(b'", "").Replace("')", "")
            }
        }

        # Increment index to query for the next code in the following iteration
        $index = ($index + 1) % $code_list.Count

        # Check if a full set of data has been gathered
        if ($index -eq 0) {
            # Print all results
            foreach ($key in $full_response.Keys) {
                if (($full_response[$key] -like "*NO DATA*") -or ($full_response[$key] -like "*CAN ERROR*")) {
                    # Convert PID to text description and print together with value
                    Write-Host (Format-Output -Key $(& mapping | Where-Object {$_.Key -eq $key}).Value -Value $full_response[$key])
                } else {
                    # Convert PID to text description and calculate associated value based on response
                    $mappingResult = (& mapping | Where-Object {$_.Key -eq $key})
                    if ($mappingResult) {
                        Write-Host (Format-Output -Key $mappingResult.Value -Value $(& mapping -code $key -value $full_response[$key]))
                    } else {
                        Write-Host "Mapping not found for PID: $key - Value: $($full_response[$key])"
                    }
                }
            }
            # Reset result placeholder and backup
            $previous_full_response = $full_response
            $full_response = @{}
            Write-Host "*****"
            Write-Host "*****"
        }
    }

    # Close the serial port
    if ($ser -ne $null -and $ser.IsOpen) {
        $ser.Close()
    }
}

# Assuming you have a PowerShell script named 'mapping.ps1' that provides the mapping functionality
# This script should either:
# 1. Output a hashtable containing the mappings (e.g., @{'0104' = 'Engine Load [0-100%]'})
# 2. Define a function named 'mapping' that takes a 'code' and optionally a 'value' and returns the corresponding text or calculated value.

# Example 'mapping.ps1' (Option 1 - Hashtable):
# @{
#     '0104' = 'Engine Load [0-100%]'
#     '0105' = 'Coolant Temperature [C]'
#     # ... other mappings
# }

# Example 'mapping.ps1' (Option 2 - Function):
# function mapping {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$code,
#         [int]$value
#     )
#
#     switch ($code) {
#         '0104' {
#             return "Engine Load [0-100%]"
#         }
#         '0105' {
#             return "Coolant Temperature [C]"
#         }
#         # ... other cases for descriptions
#     }
#
#     # Functionality to convert values based on the code
#     if ($value -ne $null) {
#         switch ($code) {
#             '0105' {
#                 return ($value - 40) # Example conversion for Celsius
#             }
#             # ... other conversion logic
#             default { return $value }
#         }
#     }
# }