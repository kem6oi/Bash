# Cybersecurity Tools

This directory contains security testing and analysis tools for penetration testing and security audits.

## Tools

### 1. Port Scanner (`port_scanner.sh`)
Scans TCP/UDP ports on target hosts.
```bash
./port_scanner.sh -h 192.168.1.1 -p 1-1000
./port_scanner.sh -h example.com -p 80,443,8080 -t tcp
```

### 2. Subnet Scanner (`subnet_scanner.sh`)
Discovers active hosts on network subnets.
```bash
./subnet_scanner.sh -s 192.168.1.0/24
./subnet_scanner.sh -s 10.0.0.0/24 -r -p
```

### 3. SSL/TLS Checker (`ssl_checker.sh`)
Analyzes SSL certificates and security.
```bash
./ssl_checker.sh -d example.com
./ssl_checker.sh -d example.com -c -P
```

### 4. Log Analyzer (`log_analyzer.sh`)
Parses logs for security events.
```bash
./log_analyzer.sh -f /var/log/auth.log
./log_analyzer.sh -t auth -w
```

### 5. Password Checker (`password_checker.sh`)
Evaluates password strength.
```bash
./password_checker.sh
./password_checker.sh -p "MyPassword123"
```

### 6. Hash Tool (`hash_tool.sh`)
Generates and verifies file hashes.
```bash
./hash_tool.sh -f /path/to/file -t sha256
./hash_tool.sh -m verify -f file.txt -e <hash>
```

### 7. Vulnerability Scanner (`vuln_scanner.sh`)
Wraps common vulnerability scanning tools.
```bash
./vuln_scanner.sh -t 192.168.1.1 -s quick
./vuln_scanner.sh -t example.com --all
```

### 8. Integrity Checker (`integrity_checker.sh`)
Monitors file changes and creates backups.
```bash
./integrity_checker.sh -m baseline -d /etc/config
./integrity_checker.sh -m check -d /etc/config
./integrity_checker.sh -m backup -d /var/www
```

## Security Notice
Use these tools only on systems you own or have explicit authorization to test.
