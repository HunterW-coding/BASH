#!/bin/bash

echo "Made By chatgpt (If you want mine then download PHOENIXSCANNER on my github!)"

# cool stuff
# Fun ASCII art intro
echo " 
   ______        __      ____                 _       __"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate IP address
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0  # Valid IP
    else
        return 1  # Invalid IP
    fi
}

# Function to scan for services using nmap
scan_services() {
    local ip="$1"
    echo "Scanning the IP address $ip for open services and versions..."
    nmap -sV $ip -oN nmap_scan.txt
    if ! grep -q "open" nmap_scan.txt; then
        echo "No open services found on the IP address. Exiting."
        rm nmap_scan.txt
        exit 0
    fi
}

# Function to search Metasploit for exploits based on nmap results
search_exploits() {
    services=$(grep "open" nmap_scan.txt | awk '{print $3 " " $4}' | sort | uniq)
    if [[ -z $services ]]; then
        echo "No services found. Exiting."
        rm nmap_scan.txt
        exit 1
    fi
    
    echo "Analyzing detected services and searching for exploits..."
    for service in $services; do
        echo "Searching for exploits for service: $service"
        msfconsole -q -x "search $service; exit" | grep "exploit" | tee -a exploits_found.txt
    done

    if [[ ! -s exploits_found.txt ]]; then
        echo "No relevant exploits found for the detected services. Exiting."
        rm nmap_scan.txt exploits_found.txt
        exit 0
    fi
}

# Function to download Metasploit exploits
download_exploits() {
    temp_dir=$(mktemp -d)
    echo "Storing exploit modules in: $temp_dir"
    
    cat exploits_found.txt | awk '{print $2}' | while read exploit; do
        echo "Downloading $exploit..."
        msfconsole -q -x "use $exploit; save -f $temp_dir/$exploit.rc; exit"
    done
    echo "All exploits have been downloaded to $temp_dir."
}

# Function to allow user to select exploits to download
interactive_exploit_selection() {
    echo "Found the following exploits:"
    awk '{print NR ": " $0}' exploits_found.txt
    read -p "Enter the numbers of the exploits to download (comma-separated), or type 'all' to download all: " exploit_choices

    if [[ $exploit_choices == "all" ]]; then
        download_exploits
    else
        temp_dir=$(mktemp -d)
        echo "Storing exploit modules in: $temp_dir"
        IFS=',' read -r -a choices_array <<< "$exploit_choices"
        for choice in "${choices_array[@]}"; do
            exploit=$(sed "${choice}q;d" exploits_found.txt | awk '{print $2}')
            echo "Downloading $exploit..."
            msfconsole -q -x "use $exploit; save -f $temp_dir/$exploit.rc; exit"
        done
        echo "Selected exploits have been downloaded to $temp_dir."
    fi
}

# Main Script Execution Starts Here

# Ensure nmap and msfconsole are installed
if ! command_exists nmap; then
    echo "Error: nmap is not installed. Please install nmap and try again."
    exit 1
fi

if ! command_exists msfconsole; then
    echo "Error: msfconsole (Metasploit) is not installed. Please install Metasploit and try again."
    exit 1
fi

# Prompt user for IP address and validate
read -p "Enter the possible vulnerable IP address: " ip_address
if ! validate_ip "$ip_address"; then
    echo "Invalid IP address format. Exiting."
    exit 1
fi

# Perform service scan and search for exploits
scan_services "$ip_address"
search_exploits

# Let the user decide which exploits to download
interactive_exploit_selection

# Clean up temporary files
rm nmap_scan.txt exploits_found.txt

# Confirm completion and prompt for exit
read -p "Press Enter to exit."
exit 0
