$port = 8080
$baseDir = "Roblox_Text_Exports"

if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    $listener.Start()
    Write-Host "Listening on $port..." -ForegroundColor Green

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request

        $reader = New-Object System.IO.StreamReader($request.InputStream)
        $rawText = $reader.ReadToEnd()

        $firstLine = $rawText.Split("`n")[0]
        $safeDate = ($firstLine -replace "EXPORT:", "").Trim() -replace '[:\\/]', '-'

        $filePath = Join-Path (Get-Location) "$baseDir\EncodedScripts_$($safeDate).txt"

        [System.IO.File]::WriteAllText($filePath, $rawText)

        Write-Host "Saved to: $filePath" -ForegroundColor Cyan

        $buffer = [System.Text.Encoding]::UTF8.GetBytes("Success")
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.Close()
    }
}
finally {
    $listener.Stop()
}