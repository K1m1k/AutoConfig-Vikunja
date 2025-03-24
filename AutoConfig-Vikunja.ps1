
# --- Configurazione iniziale ---
$vikunjaFolder = "C:\vikunja"
$nasDriveLetter = "Z:"
$nasPath = "\\192.168.1.100\Condivisione"
$gitRepoPath = "$nasDriveLetter\VikunjaFiles"

# --- Funzione: Installazione Docker ---
function Install-Docker {
    Write-Host "Verifica e installazione di Docker Desktop..." -ForegroundColor Yellow
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker non trovato. Scaricando Docker Desktop..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile "$env:TEMP\DockerInstaller.exe"
        Start-Process "$env:TEMP\DockerInstaller.exe" -ArgumentList "install --quiet" -Wait
        Write-Host "Docker installato. Riavvia il sistema se necessario." -ForegroundColor Green
    } else {
        Write-Host "Docker già installato." -ForegroundColor Green
    }
}

# --- Funzione: Creazione della cartella Vikunja ---
function Setup-VikunjaFolder {
    Write-Host "Creazione della cartella Vikunja..." -ForegroundColor Yellow
    if (-not (Test-Path $vikunjaFolder)) {
        New-Item -ItemType Directory -Path $vikunjaFolder | Out-Null
        Write-Host "Cartella Vikunja creata in $vikunjaFolder" -ForegroundColor Green
    } else {
        Write-Host "Cartella Vikunja già esistente." -ForegroundColor Green
    }
}

# --- Funzione: Configurazione del file docker-compose.yml ---
function Configure-DockerCompose {
    Write-Host "Configurazione del file docker-compose.yml..." -ForegroundColor Yellow
    $dockerComposeContent = @"
version: '3'
services:
  vikunja:
    image: vikunja/vikunja:latest
    ports:
      - "8080:80"
    volumes:
      - $vikunjaFolder\data:/app/data
    environment:
      - VIKUNJA_DATABASE_TYPE=sqlite
      - VIKUNJA_DATABASE_PATH=/app/data/vikunja.db
"@
    Set-Content -Path "$vikunjaFolder\docker-compose.yml" -Value $dockerComposeContent
    Write-Host "File docker-compose.yml creato." -ForegroundColor Green
}

# --- Funzione: Collegamento del NAS come unità di rete ---
function Connect-NAS {
    Write-Host "Collegamento del NAS come unità di rete..." -ForegroundColor Yellow
    if (-not (Get-PSDrive -Name $nasDriveLetter.Replace(":", "") -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $nasDriveLetter.Replace(":", "") -PSProvider FileSystem -Root $nasPath -Persist
        Write-Host "NAS collegato come unità $nasDriveLetter" -ForegroundColor Green
    } else {
        Write-Host "NAS già collegato come unità $nasDriveLetter" -ForegroundColor Green
    }
}

# --- Funzione: Inizializzazione del repository Git ---
function Initialize-GitRepo {
    Write-Host "Inizializzazione del repository Git..." -ForegroundColor Yellow
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git non trovato. Installazione in corso..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/latest/download/Git-2.41.0-64-bit.exe" -OutFile "$env:TEMP\GitInstaller.exe"
        Start-Process "$env:TEMP\GitInstaller.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
        Write-Host "Git installato." -ForegroundColor Green
    }

    if (-not (Test-Path $gitRepoPath)) {
        New-Item -ItemType Directory -Path $gitRepoPath | Out-Null
    }

    Push-Location $gitRepoPath
    git init
    git add .
    git commit -m "Versione iniziale"
    Pop-Location
    Write-Host "Repository Git inizializzato in $gitRepoPath" -ForegroundColor Green
}

# --- Funzione: Avvio di Vikunja ---
function Start-Vikunja {
    Write-Host "Avvio di Vikunja tramite Docker..." -ForegroundColor Yellow
    Set-Location $vikunjaFolder
    docker-compose up -d
    Write-Host "Vikunja avviato. Accedi a http://localhost:8080" -ForegroundColor Green
}

# --- Esecuzione delle funzioni ---
Install-Docker
Setup-VikunjaFolder
Configure-DockerCompose
Connect-NAS
Initialize-GitRepo
Start-Vikunja

Write-Host "Configurazione completata!" -ForegroundColor Green
