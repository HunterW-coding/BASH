#!/bin/bash

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges. Re-running with sudo..."
  exec sudo "$0" "$@"
fi

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
echo "Input a target IP address for which you want to download Metasploit scripts."
echo "Or just type 'exit' to exit."
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

while true; do
    echo -e "\nEnter the vulnerable IP address here (nothing else, just IP):"
    read -r IP_ADDR

    if [[ "$IP_ADDR" == "exit" ]]; then
        echo "Exiting script."
        exit 0
    fi

    # Validate IP address format
    if ! [[ "$IP_ADDR" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format. Please try again."
        continue
    fi

    OUTPUT_DIR="./exploits"
    
    # Create a directory for the exploits if it doesn't exist
    mkdir -p "$OUTPUT_DIR"

    # Scan the target IP address for open ports and services
    echo "Scanning IP address: $IP_ADDR..."
    nmap -sV "$IP_ADDR" -oG - | awk '/Up$/{print $2} {print $3,$4}' > "$OUTPUT_DIR/scan_results.txt"

    # Check if Metasploit is installed
    if ! command -v msfconsole &> /dev/null; then
        echo "Metasploit Framework is not installed. Please install it first."
        exit 1
    fi

    # Clone the Metasploit Framework repository (if not already cloned)
    if [ ! -d "$OUTPUT_DIR/metasploit-framework" ]; then
        echo "Cloning Metasploit Framework..."
        git clone https://github.com/rapid7/metasploit-framework.git "$OUTPUT_DIR/metasploit-framework"
    fi

    # Navigate to the Metasploit directory
    cd "$OUTPUT_DIR/metasploit-framework" || exit

    # Search for exploits related to the scanned services
    echo "Searching for relevant exploits..."
    > "$OUTPUT_DIR/relevant_exploits.txt"  # Clear the file before writing
    > "$OUTPUT_DIR/exploits_downloaded.txt" # Clear the download log
    
    # Loop through the detected services
    for service in $(awk '{print $2}' "$OUTPUT_DIR/scan_results.txt"); do
        echo "Searching for exploits related to $service..."
        
        # Find matching exploits in the Metasploit directory
        matched_exploits=$(grep -ril "$service" modules/exploits/)
        
        if [ -n "$matched_exploits" ]; then
            for exploit in $matched_exploits; do
                # Copy the exploit file to the output directory
                cp "$exploit" "$OUTPUT_DIR/"
                echo "Downloaded: $exploit to $OUTPUT_DIR/"
                echo "$exploit" >> "$OUTPUT_DIR/exploits_downloaded.txt"
            done
        else
            echo "No exploits found for $service."
        fi
    done

    # Display the results
    if [ -s "$OUTPUT_DIR/exploits_downloaded.txt" ]; then
        echo "Relevant exploits downloaded to $OUTPUT_DIR. See $OUTPUT_DIR/exploits_downloaded.txt for details."
    else
        echo "No relevant exploits found for the scanned services."
    fi

    echo "Done."
done
