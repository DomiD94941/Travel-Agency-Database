# setup_apex.ps1
Write-Host "Starting automated Oracle APEX + ORDS setup using Docker Compose..."

# 1. Pull Oracle image (jeśli nie ma)
Write-Host "Pulling Oracle 23c Free image..."
docker pull container-registry.oracle.com/database/free:latest

# 2. Start docker-compose (uruchamia kontener)
Write-Host "Starting container with docker-compose..."
docker-compose up -d

# 3. Wait until container is ready
Write-Host "Waiting for Oracle to initialize (approx. 2-3 minutes)..."
Start-Sleep -Seconds 180

# 4. Download install scripts if missing
if (!(Test-Path "./scripts/unattended_apex_install_23c.sh")) {
    Write-Host "⬇Downloading APEX unattended install scripts..."
    New-Item -ItemType Directory -Force -Path "./scripts" | Out-Null
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/unattended_apex_install_23c.sh" -OutFile "./scripts/unattended_apex_install_23c.sh"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/00_start_apex_ords_installer.sh" -OutFile "./scripts/00_start_apex_ords_installer.sh"
}

# 5. Copy scripts inside the container (safety overwrite)
Write-Host "Copying scripts into container..."
docker cp ./scripts/unattended_apex_install_23c.sh oracle23c:/home/oracle
docker cp ./scripts/00_start_apex_ords_installer.sh oracle23c:/opt/oracle/scripts/startup

# 6. Restart container (this triggers startup script)
Write-Host "Restarting container to begin installation..."
docker restart oracle23c

# 7. Wait for installation logs
Write-Host "Tailing installation logs (Ctrl+C to stop)..."
Start-Sleep -Seconds 20
docker logs -f oracle23c
