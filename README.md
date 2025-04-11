# Project: Real-time Camaro Data with Radxa Zero and ELM327 Bluetooth OBD2 Scanner

This document details my journey in connecting a Radxa Zero single-board computer to an ELM327 Bluetooth OBD2 scanner to access real-time data from my Camaro. I encountered surprisingly scarce and often inaccurate information online, leading to some trial and error. Hopefully, this guide will save others time and frustration.

**Key Steps and Workarounds:**

1.  **Operating System Choice (Armbian):** Initially, the official Ubuntu image for the Radxa Zero prevented me from binding to the necessary `rfcomm0` interface. After some research, I found that an unofficial Armbian image resolved this issue. I successfully used the Debian Bookworm minimal image for Home Assistant, available here: [https://www.armbian.com/radxa-zero/](https://www.armbian.com/radxa-zero/) (Direct download link: [https://dl.armbian.com/radxa-zero/Bookworm_current_minimal-homeassistant](https://dl.armbian.com/radxa-zero/Bookworm_current_minimal-homeassistant)).

2.  **Finding the ELM327's Bluetooth Address:**
    Use the `hcitool` utility to scan for nearby Bluetooth devices and identify your ELM327:
    ```bash
    hcitool scan
    ```
    Make sure to note down the MAC address of the ELM327.

3.  **Pairing and Trusting the Device:**
    The `bluetoothctl` tool is used for pairing and trusting. Replace `01:23:45:67:89:BA` with your ELM327's address:
    ```bash
    bluetoothctl
    pair 01:23:45:67:89:BA  # When prompted for a PIN, the default is often '1234'
    trust 01:23:45:67:89:BA
    exit
    ```
    **Important Note:** You might be tempted to use the `connect` command within `bluetoothctl`. However, this will likely fail with a `Failed to connect: org.bluez.Error.NotAvailable br-connection-profile-unavailable` error. This is expected behavior for this type of connection, so don't spend time troubleshooting it.

4.  **Discovering the RFCOMM Channel:**
    The Service Discovery Protocol (SDP) records of the ELM327 contain the crucial RFCOMM channel number. Use the following command, replacing the address:
    ```bash
    sdptool records 01:23:45:67:89:BA
    ```
    Look for a section related to Serial Port Profile (SPP) and note the "Channel" value. This was a key piece of information that took time to uncover.

5.  **Binding the RFCOMM Channel to a Serial Port:**
    The `rfcomm` command is used to create a virtual serial port (`/dev/rfcomm0`) linked to the ELM327's Bluetooth address and the channel number you found. Replace `2` with your actual channel number:
    ```bash
    sudo rfcomm bind 0 01:23:45:67:89:BA 2
    ```

6.  **Ensuring Persistent Binding on Boot:**
    To automatically bind the RFCOMM channel every time the Radxa Zero starts, add the `rfcomm bind` command to the `/etc/rc.local` file. Open it with:
    ```bash
    sudo nano /etc/rc.local
    ```
    Add the `rfcomm bind` line (from step 5) before the `exit 0` line. Save and exit the file.

7.  **Verifying the Connection:**
    You can use the `screen` utility to directly interact with the newly created serial port:
    ```bash
    screen /dev/rfcomm0
    ```
    Inside the `screen` session, type the AT command `atz` and press Enter. If the connection is successful, you should receive a response from the ELM327, such as `OKELM327 v2.1`. To exit `screen`, press `Ctrl+a` followed by `k`.

Hopefully, this detailed guide will help you successfully connect your Radxa Zero to your ELM327 OBD2 scanner!
