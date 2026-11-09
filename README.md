# SSH Vulnerability Scanner

A Bash script for scanning SSH servers for common misconfigurations, weak algorithms, and known vulnerabilities. Designed for authorized security testing only.

## ⚠️ Legal Disclaimer

**This tool is for authorized security testing only.** Only use on systems you own or have explicit written permission to test. Unauthorized scanning of systems may violate laws and regulations. The authors assume no liability for misuse.

## Features

- **Connectivity Testing**: Verifies SSH port accessibility
- **Banner Grabbing**: Retrieves and displays SSH version information
- **Algorithm Analysis**: Checks for weak ciphers, MACs, key exchange, and host key algorithms using nmap
- **Vulnerability Checks**:
  - Shellshock (CVE-2014-6271)
  - OpenSSH version-specific vulnerabilities (CVE-2016-6210, CVE-2019-6111, etc.)
  - Weak default configurations (root login, password authentication)
- **Host Key Analysis**: Identifies key types and highlights weak/deprecated keys

## Requirements

- Bash 4.0+
- OpenSSH client (`ssh`, `ssh-keyscan`)
- Netcat (`nc`) - OpenBSD variant recommended
- Nmap with `ssh2-enum-algos` script

### Installation (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install openssh-client netcat-openbsd nmap                                                                                                
                                                                                                                                                                              
### Installation (RHEL/CentOS/Fedora)                                                                                                                                         
sudo dnf install openssh-clients nmap-ncat nmap                                                                                                                               
                                                                                                                                                                              
### Installation (macOS)                                                                                                                                                      
brew install openssh nmap                                                                                                                                                     
                                                                                                                                                                              
## Usage                                                                                                                                                                      
```sh
./ssh_vuln_scanner.sh [OPTIONS] <target_host>                                                                                                                                 
```
                                                                                                                                                                              
### Options                                                                                                                                                                   
                                                                                                                                                                              
| Option | Description | Default |                                                                                                                                            
                                                                                                                                                                              
|--------|-------------|---------|                                                                                                                                            
                                                                                                                                                                              
| `-p, --port PORT` | Target SSH port | 22 |                                                                                                                                  
                                                                                                                                                                              
| `-t, --timeout SEC` | Connection timeout in seconds | 5 |                                                                                                                   
                                                                                                                                                                              
| `-v, --verbose` | Enable verbose output | false |                                                                                                                           
                                                                                                                                                                              
| `-h, --help` | Show help message | - |                                                                                                                                      
                                                                                                                                                                              
### Examples                                                                                                                                                                  

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Basic scan                                                                                                                                                                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```sh
./ssh_vuln_scanner.sh 192.168.1.100                                                                                                                                           
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Scan custom port with verbose output                                                                                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```sh
./ssh_vuln_scanner.sh -p 2222 -v 192.168.1.100                                                                                                                                
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Scan with extended timeout                                                                                                                                                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```sh
./ssh_vuln_scanner.sh -t 10 192.168.1.100                                                                                                                                     
```
                                                                                                                                                                              
## Sample Output                                                                                                                                                              

=== SSH Vulnerability Scanner ===                                                                                                                                             

Target: 192.168.1.100:22                                                                                                                                                      

Timeout: 5s                                                                                                                                                                   

[+] SSH port 22 is open on 192.168.1.100                                                                                                                                      

[+] SSH Banner: SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2                                                                                                                       

Detected version string: SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2                                                                                                              

=== Algorithm Analysis ===                                                                                                                                                    

Encryption Algorithms (Ciphers):                                                                                                                                              

[WEAK] aes128-cbc                                                                                                                                                             

[WEAK] aes192-cbc                                                                                                                                                             

[WEAK] aes256-cbc                                                                                                                                                             

Message Authentication Codes (MACs):                                                                                                                                          

[WEAK] hmac-sha1-96                                                                                                                                                           

Key Exchange Algorithms:                                                                                                                                                      

[WEAK] diffie-hellman-group14-sha1                                                                                                                                            

Host Key Algorithms:                                                                                                                                                          

[POTENTIALLY WEAK] ssh-rsa (consider using ed25519 or ecdsa-sha2-nistp256)                                                                                                    

=== Vulnerability Checks ===                                                                                                                                                  

[OK] Not vulnerable to Shellshock (CVE-2014-6271)                                                                                                                             

[WARNING] Multiple potential vulnerabilities in versions < 8.2                                                                                                                

                                                                                                                                                                              
     Consider upgrading to OpenSSH 8.2 or later                                                                                                                               
                                                                                                                                                                              

[OK] Root login with password disabled (publickey only)                                                                                                                       

[WARNING] Password authentication may be enabled                                                                                                                              

=== Host Key Analysis ===                                                                                                                                                     

[INFO] RSA host key found (check key size - should be >= 2048 bits)                                                                                                           

[OK] ECDSA host key found (ecdsa-sha2-nistp256)                                                                                                                               

[OK] Ed25519 host key found (recommended)                                                                                                                                     

=== Scan Complete ===                                                                                                                                                         

Remember to only test systems you have explicit permission to assess!                                                                                                         
                                                                                                                                                                              
## Vulnerability Coverage                                                                                                                                                     
                                                                                                                                                                              
| Vulnerability | CVE | Detection Method |                                                                                                                                    
                                                                                                                                                                              
|---------------|-----|------------------|                                                                                                                                    
                                                                                                                                                                              
| Shellshock | CVE-2014-6271 | Command injection test |                                                                                                                       
                                                                                                                                                                              
| Username Enumeration | CVE-2016-6210 | Version detection (OpenSSH 7.2p1-7.4p1) |                                                                                            
                                                                                                                                                                              
| SCP Directory Traversal | CVE-2019-6111 | Version detection (OpenSSH < 7.7) |                                                                                               
                                                                                                                                                                              
| Multiple Vulnerabilities | Various | Version detection (OpenSSH < 8.2) |                                                                                                    
                                                                                                                                                                              
| Weak Algorithms | N/A | Nmap script enumeration |                                                                                                                           
                                                                                                                                                                              
| Weak Host Keys | N/A | Key type analysis |                                                                                                                                  
                                                                                                                                                                              
| Insecure Configurations | N/A | Authentication method testing |                                                                                                             
                                                                                                                                                                              
## Limitations                                                                                                                                                                
                                                                                                                                                                              
1. **Version-based checks only**: Cannot confirm exploitation, only potential vulnerability                                                                                   
                                                                                                                                                                              
2. **Requires network access**: Must be able to reach target SSH port                                                                                                         
                                                                                                                                                                              
3. **Nmap dependency**: Algorithm checks require nmap with scripting engine                                                                                                   
                                                                                                                                                                              
4. **No credential testing**: Does not attempt brute force or credential stuffing                                                                                             
                                                                                                                                                                              
5. **False positives possible**: Version checks may not account for backported patches                                                                                        
                                                                                                                                                                              
## Contributing                                                                                                                                                               
                                                                                                                                                                              
1. Fork the repository                                                                                                                                                        
                                                                                                                                                                              
2. Create a feature branch (`git checkout -b feature/improvement`)                                                                                                            
                                                                                                                                                                              
3. Commit your changes (`git commit -am 'Add new feature'`)                                                                                                                   
                                                                                                                                                                              
4. Push to the branch (`git push origin feature/improvement`)                                                                                                                 
                                                                                                                                                                              
5. Open a Pull Request                                                                                                                                                        
                                                                                                                                                                              
## License                                                                                                                                                                    
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.                                                                                 
                                                                                                                                                                              
## Acknowledgments                                                                                                                                                            
- Nmap Project for the `ssh2-enum-algos` script                                                                                                                               
- OpenSSH team for secure SSH implementation                                                                                                                                  
- Security researchers who discovered the referenced vulnerabilities
