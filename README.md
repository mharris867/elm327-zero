# elm327-zero
Bluetooth OBD2 scanner connected to a Radxa Zero for Real time data from my Camaro

There is nothing but bad information on connecting a single board computer (Raspberry PI Zero, Radxa Zero in my case..) to a bluetooth to a elm327 OBD2 device. 
1. Had to install Armbian instead of the official ubuntu image for the Radxa Zero because it would not allow me to bind to rfcomm0. I found the link to the unofficial Armbian was referenced in old releases that ultimately led me to https://www.armbian.com/radxa-zero/ where I downloaded the debian bookworm image https://dl.armbian.com/radxa-zero/Bookworm_current_minimal-homeassistant.

2. hcitool scan # get and copy the address of the elm327
3. bluetoothctl # use this tool to pair and trust the elm327
- pair 01:23:45:67:89:BA # when prompted for pin enter 1234
- trust 01:23:45:67:89:BA # so pairing will persist
- exit # exit bluetoothctl. do not try to run the connect command because it will error with Failed to connect: org.bluez.Error.NotAvailable br-connection-profile-unavailable THIS IS EXPECTED SO DONT BOTHER TRYING.
sdptool records 01:23:45:67:89:BA # and get the channel number. I lost tons of time on this. 
sudo rfcomm bind 0 01:23:45:67:89:BA 2 # command that needs to be run to create /dev/rfcomm0 for communication. 0 = rfcomm0 and the 2 at the end is my channel from the above command.
sudo nano /etc/rc.local # and add the sudo rfcomm bind 0 01:23:45:67:89:BA 2 from above to bind on next boot of device.
screen /dev/rfcomm0 # this connects to the serialport
- atz # atz command inside screen tests connectivity and displays the version of the elm327
