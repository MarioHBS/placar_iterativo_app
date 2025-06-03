# Script PowerShell para executar testes em modo watch
# Para usar: .\.\test\watch_tests.ps1

Write-Host "Iniciando modo watch para testes Flutter..." -ForegroundColor Green
Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Yellow
Write-Host ""

# Função para executar testes
function Run-Tests {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Executando testes..." -ForegroundColor Cyan
    flutter test
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testes concluídos. Aguardando mudanças..." -ForegroundColor Green
    Write-Host ""
}

# Executar testes inicialmente
Run-Tests

# Configurar FileSystemWatcher para monitorar mudanças
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Filtrar apenas arquivos .dart
$watcher.Filter = "*.dart"

# Registrar evento para mudanças de arquivo
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    
    # Ignorar arquivos gerados automaticamente
    if ($path -match "\.g\.dart$" -or $path -match "\.freezed\.dart$" -or $path -match "\.mocks\.dart$") {
        return
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Arquivo modificado: $path" -ForegroundColor Yellow
    
    # Aguardar um pouco para evitar múltiplas execuções
    Start-Sleep -Seconds 1
    
    # Executar testes
    Run-Tests
}

# Registrar eventos
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action
Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action

try {
    # Manter o script rodando
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Limpar recursos
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Host "Watch mode finalizado." -ForegroundColor Red
}