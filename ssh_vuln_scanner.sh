#!/bin/bash

# SSH Vulnerability Scanner
# For authorized security testing only
# Checks for common SSH misconfigurations and known vulnerabilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TARGET_HOST=""
TARGET_PORT=22
TIMEOUT=5
VERBOSE=false

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS] <target_host>"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT       Target SSH port (default: 22)"
    echo "  -t, --timeout SEC     Connection timeout in seconds (default: 5)"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Example: $0 -p 2222 -v 192.168.1.100"
    echo ""
    echo "WARNING: Only use on systems you own or have explicit permission to test!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            TARGET_PORT="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            TARGET_HOST="$1"
            shift
            ;;
    esac
done

# Validate target
if [[ -z "$TARGET_HOST" ]]; then
    echo -e "${RED}Error: Target host not specified${NC}"
    show_help
    exit 1
fi

# Function to print verbose messages
verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${YELLOW}[VERBOSE] $1${NC}"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
check_tools() {
    local missing_tools=()
    
    for tool in ssh nc ssh-keyscan nmap; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them first (e.g., apt-get install openssh-client netcat-openbsd nmap)"
        exit 1
    fi
}

# Test SSH connectivity
test_connectivity() {
    verbose "Testing connectivity to $TARGET_HOST:$TARGET_PORT..."
    
    if nc -z -w "$TIMEOUT" "$TARGET_HOST" "$TARGET_PORT" >/dev/null 2>&1; then
        echo -e "${GREEN}[+] SSH port $TARGET_PORT is open on $TARGET_HOST${NC}"
        return 0
    else
        echo -e "${RED}[-] Cannot connect to SSH port $TARGET_PORT on $TARGET_HOST${NC}"
        return 1
    fi
}

# Get SSH banner and version
get_ssh_banner() {
    verbose "Retrieving SSH banner..."
    local banner
    banner=$(nc -w "$TIMEOUT" "$TARGET_HOST" "$TARGET_PORT" 2>/dev/null | head -1)
    
    if [[ -n "$banner" ]]; then
        echo -e "${GREEN}[+] SSH Banner: $banner${NC}"
        SSH_VERSION=$(echo "$banner" | grep -oE 'SSH-[0-9.]+-[^ ]+' | head -1)
        verbose "Detected version string: $SSH_VERSION"
    else
        echo -e "${RED}[-] Could not retrieve SSH banner${NC}"
        SSH_VERSION=""
    fi
}

# Check for weak algorithms
check_algorithms() {
    verbose "Checking supported algorithms..."
    
    # Use nmap to get algorithm information
    local nmap_output
    nmap_output=$(nmap -p "$TARGET_PORT" --script ssh2-enum-algos "$TARGET_HOST" 2>/dev/null)
    
    if [[ -z "$nmap_output" ]]; then
        echo -e "${YELLOW}[!] Could not retrieve algorithm information (nmap script failed)${NC}"
        return
    fi
    
    # Check for weak ciphers
    local weak_ciphers=("3des-cbc" "aes128-cbc" "aes192-cbc" "aes256-cbc" "blowfish-cbc" "cast128-cbc" "arcfour" "arcfour128" "arcfour256")
    local weak_macs=("hmac-md5" "hmac-md5-96" "hmac-sha1-96" "hmac-ripemd160" "umac-64@openssh.com")
    local weak_kex=("diffie-hellman-group1-sha1" "diffie-hellman-group14-sha1" "diffie-hellman-group-exchange-sha1")
    local weak_hostkey=("ssh-dss" "ssh-rsa")
    
    echo -e "\n${YELLOW}=== Algorithm Analysis ===${NC}"
    
    # Check ciphers
    echo -e "\n${YELLOW}Encryption Algorithms (Ciphers):${NC}"
    for cipher in "${weak_ciphers[@]}"; do
        if echo "$nmap_output" | grep -qi "$cipher"; then
            echo -e "${RED}[WEAK] $cipher${NC}"
        fi
    done
    
    # Check MACs
    echo -e "\n${YELLOW}Message Authentication Codes (MACs):${NC}"
    for mac in "${weak_macs[@]}"; do
        if echo "$nmap_output" | grep -qi "$mac"; then
            echo -e "${RED}[WEAK] $mac${NC}"
        fi
    done
    
    # Check Key Exchange
    echo -e "\n${YELLOW}Key Exchange Algorithms:${NC}"
    for kex in "${weak_kex[@]}"; do
        if echo "$nmap_output" | grep -qi "$kex"; then
            echo -e "${RED}[WEAK] $kex${NC}"
        fi
    done
    
    # Check Host Key Algorithms
    echo -e "\n${YELLOW}Host Key Algorithms:${NC}"
    for hk in "${weak_hostkey[@]}"; do
        if echo "$nmap_output" | grep -qi "$hk"; then
            echo -e "${YELLOW}[POTENTIALLY WEAK] $hk (consider using ed25519 or ecdsa-sha2-nistp256)${NC}"
        fi
    done
}

# Check for known vulnerabilities
check_vulnerabilities() {
    verbose "Checking for known vulnerabilities..."
    
    echo -e "\n${YELLOW}=== Vulnerability Checks ===${NC}"
    
    # 1. Check for Shellshock (CVE-2014-6271) - not SSH but often confused
    verbose "Checking for Shellshock (CVE-2014-6271)..."
    if ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=no -p "$TARGET_PORT" "$TARGET_HOST" 'env x="() { :;}; echo VULNERABLE" bash -c "echo TEST"' 2>/dev/null | grep -q "VULNERABLE"; then
        echo -e "${RED}[CRITICAL] Shellshock vulnerability (CVE-2014-6271) detected!${NC}"
    else
        echo -e "${GREEN}[OK] Not vulnerable to Shellshock (CVE-2014-6271)${NC}"
    fi
    
    # 2. Check for SSH version specific vulnerabilities
    if [[ -n "$SSH_VERSION" ]]; then
        verbose "Checking version-specific vulnerabilities for $SSH_VERSION..."
        
        # OpenSSH 7.2p1 - 7.4p1: Username enumeration (CVE-2016-6210)
        if echo "$SSH_VERSION" | grep -qE 'OpenSSH_7\.[234]'; then
            echo -e "${YELLOW}[WARNING] Potential username enumeration vulnerability (CVE-2016-6210)${NC}"
            echo "         Versions 7.2p1-7.4p1 may allow username enumeration via timing attack"
        fi
        
        # OpenSSH < 7.7: scp vulnerability (CVE-2019-6111)
        if echo "$SSH_VERSION" | grep -qE 'OpenSSH_([0-6]\.|7\.[0-6])'; then
            echo -e "${YELLOW}[WARNING] Potential scp vulnerability (CVE-2019-6111)${NC}"
            echo "         Versions < 7.7 may be vulnerable to scp client directory traversal"
        fi
        
        # OpenSSH < 8.2: Various vulnerabilities
        if echo "$SSH_VERSION" | grep -qE 'OpenSSH_([0-7]\.|8\.[01])'; then
            echo -e "${YELLOW}[WARNING] Multiple potential vulnerabilities in versions < 8.2${NC}"
            echo "         Consider upgrading to OpenSSH 8.2 or later"
        fi
    fi
    
    # 3. Check for weak default configurations
    verbose "Checking for weak default configurations..."
    
    # Test root login permission
    if ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=no -p "$TARGET_PORT" "root@$TARGET_HOST" "exit" 2>&1 | grep -q "Permission denied (publickey)"; then
        echo -e "${GREEN}[OK] Root login with password disabled (publickey only)${NC}"
    elif ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=no -p "$TARGET_PORT" "root@$TARGET_HOST" "exit" 2>&1 | grep -q "Permission denied"; then
        echo -e "${YELLOW}[WARNING] Root login may be permitted (check PermitRootLogin setting)${NC}"
    fi
    
    # Test password authentication
    if ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=no -o PasswordAuthentication=no -p "$TARGET_PORT" "$TARGET_HOST" "exit" 2>&1 | grep -q "Permission denied (publickey)"; then
        echo -e "${GREEN}[OK] Password authentication appears to be disabled${NC}"
    else
        echo -e "${YELLOW}[WARNING] Password authentication may be enabled${NC}"
    fi
}

# Check SSH host keys
check_host_keys() {
    verbose "Retrieving and analyzing host keys..."
    
    local keyscan_output
    keyscan_output=$(ssh-keyscan -p "$TARGET_PORT" -T "$TIMEOUT" "$TARGET_HOST" 2>/dev/null)
    
    if [[ -z "$keyscan_output" ]]; then
        echo -e "${RED}[-] Could not retrieve host keys${NC}"
        return
    fi
    
    echo -e "\n${YELLOW}=== Host Key Analysis ===${NC}"
    echo "$keyscan_output" | while read -r line; do
        if [[ -n "$line" ]]; then
            local key_type=$(echo "$line" | awk '{print $3}')
            local key_bits=""
            
            # Extract key size for RSA keys
            if [[ "$key_type" == "ssh-rsa" ]]; then
                # This is a simplified check - in reality you'd need to parse the key
                key_bits=" (check key size - should be >= 2048 bits)"
            fi
            
            case "$key_type" in
                "ssh-rsa")
                    echo -e "${YELLOW}[INFO] RSA host key found$key_bits${NC}"
                    ;;
                "ssh-dss")
                    echo -e "${RED}[WEAK] DSA host key found (deprecated, max 1024 bits)${NC}"
                    ;;
                "ecdsa-sha2-nistp256"|"ecdsa-sha2-nistp384"|"ecdsa-sha2-nistp521")
                    echo -e "${GREEN}[OK] ECDSA host key found ($key_type)${NC}"
                    ;;
                "ssh-ed25519")
                    echo -e "${GREEN}[OK] Ed25519 host key found (recommended)${NC}"
                    ;;
                *)
                    echo -e "${YELLOW}[INFO] Unknown key type: $key_type${NC}"
                    ;;
            esac
        fi
    done
}

# Main execution
main() {
    echo -e "${YELLOW}=== SSH Vulnerability Scanner ===${NC}"
    echo "Target: $TARGET_HOST:$TARGET_PORT"
    echo "Timeout: ${TIMEOUT}s"
    echo ""
    
    check_tools
    
    if ! test_connectivity; then
        exit 1
    fi
    
    get_ssh_banner
    check_algorithms
    check_vulnerabilities
    check_host_keys
    
    echo -e "\n${YELLOW}=== Scan Complete ===${NC}"
    echo "Remember to only test systems you have explicit permission to assess!"
}

# Run main function
main
