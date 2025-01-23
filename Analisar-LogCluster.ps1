# Esse script serve para analisar o arquivo log do serviço de cluster do windows.
# ele gera um resumo dos erros e alertas do arquivo e mostra um pequeno resumo ordenado pela quantidade de erros.
# para gerar os arquivos de log: 
# Ex.: usando o powershell acesse o diretório onde quer gerar o arquivo de log
# Get-ClusterLog -Destination .
# isso pode demorar alguns segundos e ele vai gerar X arquivos onde X é a quantidade de nós do seu cluster.
# esse script analisa apenas 1 arquivo de log.

# Exemplo de uso
# Analisar-LogCluster -CaminhoDoLog "C:\Caminho\Para\SeuArquivoDeLog.log"

function Analisar-LogCluster {
    param (
        [string]$CaminhoDoLog
    )

    if (-Not (Test-Path $CaminhoDoLog)) {
        Write-Host "O caminho do log não existe: $CaminhoDoLog"
        return
    }

    # Inicializar contadores
    $totalEntradas = 0
    $totalErros = 0
    $totalWarnings = 0
    $detalhesErros = @{}
    $detalhesWarnings = @{}

    # Ler o arquivo de log
    $linhas = Get-Content $CaminhoDoLog

    foreach ($linha in $linhas) {
        $totalEntradas++

        # Verificar se a linha contém erro ou aviso
        if ($linha -match '\sERR\s') {
            $totalErros++
            # Capturar a descrição do erro
            if ($linha -match 'ERR\s+(.*)') {
                $descricaoErro = $matches[1]
                # Normalizar a descrição removendo partes variáveis
                $descricaoErroNormalizada = $descricaoErro -replace 'channel to remote endpoint \d+\.\d+\.\d+\.\d+:\~\d+\~', 'channel to remote endpoint <IP>:<PORT>'
                $descricaoErroNormalizada = $descricaoErroNormalizada -replace 'Received wrong header info: .*', 'Received wrong header info: <HEADER_INFO>'
                $descricaoErroNormalizada = $descricaoErroNormalizada -replace '\[CHANNEL \d+\.\d+\.\d+\.\d+:\~\d+\~\]', '[CHANNEL <IP>:<PORT>]' # Normaliza canais
                $descricaoErroNormalizada = $descricaoErroNormalizada -replace 'Failed to retrieve the results of overlapped I/O: \d+', 'Failed to retrieve the results of overlapped I/O: <ERROR_CODE>' # Normaliza códigos de erro
                if (-not $detalhesErros.ContainsKey($descricaoErroNormalizada.Trim())) {
                    $detalhesErros[$descricaoErroNormalizada.Trim()] = 0
                }
                $detalhesErros[$descricaoErroNormalizada.Trim()]++
            }
        } elseif ($linha -match '\sWARN\s') {
            $totalWarnings++
            # Capturar a descrição do aviso
            if ($linha -match 'WARN\s+(.*)') {
                $descricaoWarning = $matches[1]
                # Normalizar a descrição removendo partes variáveis
                $descricaoWarningNormalizada = $descricaoWarning -replace '\[.*?\]', ''
                if (-not $detalhesWarnings.ContainsKey($descricaoWarningNormalizada.Trim())) {
                    $detalhesWarnings[$descricaoWarningNormalizada.Trim()] = 0
                }
                $detalhesWarnings[$descricaoWarningNormalizada.Trim()]++
            }
        }
    }

    # Exibir resumo
    Write-Host "Resumo do Log:"
    Write-Host "Total de Entradas: $totalEntradas"
    Write-Host "Total de Erros: $totalErros"
    Write-Host "Total de Warnings: $totalWarnings"

    if ($totalErros -gt 0) {
        Write-Host "Detalhes dos Erros (Ordenados):"
        $detalhesErros.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
            Write-Host "Erro: $($_.Key) - Quantidade: $($_.Value)"
        }
    }

    if ($totalWarnings -gt 0) {
        Write-Host "Detalhes dos Warnings (Ordenados):"
        $detalhesWarnings.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
            Write-Host "Warning: $($_.Key) - Quantidade: $($_.Value)"
        }
    }
}

# Exemplo de uso
# Analisar-LogCluster -CaminhoDoLog "C:\Caminho\Para\SeuArquivoDeLog.log"
