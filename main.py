import serial
from os import system
import mapping

# Constant values
code_list = ['0104', '0105', '010A', '010C', '0110', '0111', '0123', '0133', '013C', '0143', '0144', '0145', '0146',
             '0149', '014A', '0162', '0163', '01A6']
safety_counter = 100


# Send PID to serial port, read response and handle result
def query(ser_comm, code):
    # Send encoded PID
    ser_comm.write((code + '\r').encode())
    safety = 0
    running = True
    trigger = 0
    full_frame = bytearray()
    while running:
        safety += 1
        # Read response
        response = ser_comm.read(1)
        full_frame.extend(response)
        # Analyse response to look for EOF "\r\r>"
        if response == b'\r' or response == b'>':
            if response == b'>' and trigger == 2:
                running = False
            elif response == b'\r':
                trigger += 1
        else:
            trigger = 0
        # Safety catch to avoid blockages
        if safety == safety_counter:
            running = False
    return full_frame


# Format and print a human-readable presentation of the fetched data
def printing(key, value):
    full_text = ""
    # Check if the PID's text description has [unit of mesure]
    if "[" in key:
        full_text = str(key[0:key.index("[")]).strip() + ": " + str(value)
        if value != "NO DATA" and value != "CAN ERROR":
            full_text += " " + str(key[key.index("["):]).strip()
    else:
        full_text = str(key).strip() + ": " + str(value).strip()
    return full_text


# MAIN
if __name__ == '__main__':
    # Open bluetooth connection
    try:
        system('bluetoothctl connect 00:1D:A5:01:80:C7')
        system('sudo rfcomm bind rfcomm0 00:1D:A5:01:80:C7')
    except Exception as e:
        print(e)
    # Initialise the serial connection instance
    ser = serial.Serial(port='/dev/rfcomm0',
                        baudrate=115200,
                        parity=serial.PARITY_NONE,
                        stopbits=serial.STOPBITS_ONE,
                        bytesize=serial.EIGHTBITS,
                        timeout=0.3)
    # Declaration of variables
    run = True
    index = 0
    full_response = dict()
    previous_full_response = dict()
    # Open the serial communication
    try:
        ser.open()
    except Exception as e:
        print(e)
    # Main loop
    while run:
        # Set the PID to query
        code = code_list[index]
        # Query and get response
        response = query(ser, code)
        # Analyse response
        # If no data has been fetched, use the previous result, otherwise format the response
        if ("NO DATA" in str(response)) or ("CAN ERROR" in str(response)):
            if code in previous_full_response:
                full_response[code] = previous_full_response[code]
            else:
                full_response[code] = str(response).replace("bytearray(b'", "").replace("')", "")
        else:
            try:
                # Get data from the response and convert to Integer
                full_response[code] = int(response[11:-4].replace(b' ', b''), 16)
            except Exception as e:
                # Save data as is, if it cannot be converted to Integer
                full_response[code] = str(response).replace("bytearray(b'", "").replace("')", "")

        # Increment index to query for the next code in the following iteration
        index = (index + 1) % len(code_list)
        # Check if a full set of data has been gathered
        if index == 0:
            # Print all results
            for key in full_response:
                if ("NO DATA" in str(full_response[key])) or ("CAN ERROR" in str(full_response[key])):
                    # Convert PID to text description and print together with value
                    print(printing(mapping.convert_pid(key), str(full_response[key])))
                else:
                    # Convert PID to text description and calculate associated value based on response
                    print(printing(mapping.convert_pid(key), mapping.convert_value(key, full_response[key])))
            # Reset result placeholder and backup
            previous_full_response = full_response
            full_response = dict()
            print("*****")
            print("*****")