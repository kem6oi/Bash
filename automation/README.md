# Automation Tools

System automation scripts for monitoring, backup, and deployment tasks.

## Tools

### 1. Health Monitor (`health_monitor.sh`)
Monitors system resources (CPU, memory, disk).
```bash
./health_monitor.sh -i 10 -c 90 -m 85
./health_monitor.sh -C -o health.log
```

### 2. Auto Backup (`auto_backup.sh`)
Automated backup with rotation.
```bash
./auto_backup.sh -s /var/www/html -b /backups
./auto_backup.sh -s /data -r 14
```

### 3. Service Watchdog (`service_watchdog.sh`)
Monitors and restarts services.
```bash
./service_watchdog.sh -s nginx -s mysql -i 60
./service_watchdog.sh -s apache2 -m 5
```

### 4. Deploy Helper (`deploy_helper.sh`)
Simplifies deployment workflows.
```bash
./deploy_helper.sh -p /var/www/app -b production
./deploy_helper.sh -p /opt/app -T -r nginx
```

### 5. Batch Processor (`batch_processor.sh`)
Bulk file operations.
```bash
./batch_processor.sh -o rename -p "*.jpg" -P "photo_"
./batch_processor.sh -o compress -p "*.log"
```

### 6. API Tester (`api_tester.sh`)
Tests REST API endpoints.
```bash
./api_tester.sh -u https://api.example.com/users
./api_tester.sh -u https://api.example.com/data -m POST -d '{"key":"value"}'
```

## Scheduling
Add these to cron for automated execution:
```cron
0 2 * * * /path/to/auto_backup.sh -s /data -b /backups
*/5 * * * * /path/to/service_watchdog.sh -s nginx -1
0 * * * * /path/to/health_monitor.sh -c 90 -m 85 -o /var/log/health.log
```
