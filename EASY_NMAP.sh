#!/bin/bash

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

# Get the current network subnet
get_current_subnet() {
    # Use 'ip' command to get the local IP and subnet
    local ip_info
    ip_info=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')
    
    # Extract the subnet
    for ip in $ip_info; do
        echo "${ip%/*}"
    done | cut -d'/' -f1
}

# Display the menu
function show_menu {
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    echo "                 Simplified Nmap Script              "
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    echo "1) Scan a single IP address"
    echo "2) Scan a range of IP addresses"
    echo "3) Scan a subnet"
    echo "4) Scan a file of IP addresses"
    echo "5) Scan the current network"
    echo "6) Exit"
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
}

# Function to perform the scan
function perform_scan {
    local scan_type=$1
    local target=$2
    local output_file=$3

    case $scan_type in
        single)
            nmap -sV "$target" -oN "$output_file"
            ;;
        range)
            nmap -sV "$target" -oN "$output_file"
            ;;
        subnet)
            nmap -sV "$target" -oN "$output_file"
            ;;
        file)
            nmap -sV -iL "$target" -oN "$output_file"
            ;;
        network)
            nmap -sV "$target" -oN "$output_file"
            ;;
    esac

    echo "Scan completed. Results saved in $output_file."
}

# Main loop
while true; do
    show_menu
    read -p "Choose an option (1-6): " choice

    case $choice in
        1)
            read -p "Enter the IP address to scan: " ip_address
            perform_scan single "$ip_address" "scan_result_${ip_address}.txt"
            ;;
        2)
            read -p "Enter the range of IP addresses (e.g., 192.168.1.1-10): " ip_range
            perform_scan range "$ip_range" "scan_result_range_${ip_range//-/to_}.txt"
            ;;
        3)
            read -p "Enter the subnet (e.g., 192.168.1.0/24): " subnet
            perform_scan subnet "$subnet" "scan_result_subnet_${subnet//\//_}.txt"
            ;;
        4)
            read -p "Enter the filename containing IP addresses: " filename
            perform_scan file "$filename" "scan_result_file_${filename//./_}.txt"
            ;;
        5)
            current_subnet=$(get_current_subnet)
            if [ -n "$current_subnet" ]; then
                echo "Scanning the current network: $current_subnet"
                perform_scan network "$current_subnet" "scan_result_network_${current_subnet//\//_}.txt"
            else
                echo "Could not determine the current network."
            fi
            ;;
        6)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose between 1-6."
            ;;
    esac
done
