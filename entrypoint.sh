#!/bin/bash -ex

if [ $(grep -ci $CUPSADMIN /etc/shadow) -eq 0 ]; then
    useradd -r -G lpadmin -M $CUPSADMIN

    # add password
    echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

    # add tzdata
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# restore default cups config in case user does not have any
if [ ! -f /etc/cups/cupsd.conf ]; then
    cp -rpn /etc/cups-bak/* /etc/cups/
fi

service cups start ; sleep 2

lpadmin -p LBP7018C -P /usr/share/cups/model/CNCUPSLBP7018CCAPTK.ppd -v ccp://localhost:59787 -E
lpstat -p
ccpdadmin -p LBP7018C -P /usr/share/cups/model/CNCUPSLBP7018CCAPTK.ppd  -o /dev/usb/lp0

echo "Wait to initialize" ; sleep 1
service ccpd start

COMMAND="ccpdadmin"

# String to wait for
SEARCH_STRING="localhost:59787"

# Loop until the string is found in the command output
while true; do
    # Run the command and capture the output
    OUTPUT=$($COMMAND)
    
    # Check if the output contains the search string
    if echo "$OUTPUT" | grep -q "$SEARCH_STRING"; then
        echo "String '$SEARCH_STRING' found in command output."
        break
    else
        echo "Waiting printer to became ready '$SEARCH_STRING'..."
    fi
    
    # Sleep for a few seconds before checking again
    sleep 2
done

tail -f /var/log/cups/error_log

