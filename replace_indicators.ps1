$files = Get-ChildItem -Path "lib" -Recurse -Filter *.dart | Where-Object { $_.Name -ne 'crypto_loading_indicator.dart' }
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'CircularProgressIndicator') {
        if ($content -notmatch 'crypto_loading_indicator.dart') {
            $content = $content -replace "(?m)^(import 'package:flutter/material\.dart';)$", "$1
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';"
        }
        
        # Replace instances of CircularProgressIndicator(...) or just CircularProgressIndicator()
        # CircularProgressIndicator()
        $content = $content -replace 'CircularProgressIndicator\(\)', 'CryptoLoadingIndicator()'
        
        # CircularProgressIndicator(strokeWidth: 2) -> CryptoLoadingIndicator(size: 30) (or whatever size)
        $content = $content -replace 'CircularProgressIndicator\(strokeWidth:\s*\d+(\.\d+)?\)', 'CryptoLoadingIndicator(size: 30)'
        
        # CircularProgressIndicator(color: ...)
        $content = $content -replace 'CircularProgressIndicator\(color:[^\)]+\)', 'CryptoLoadingIndicator(size: 40)'
        
        # Any remaining that might have been multiline
        $content = $content -replace 'CircularProgressIndicator', 'CryptoLoadingIndicator'
        
        Set-Content -Path $f.FullName -Value $content -Encoding utf8
        Write-Host "Updated "
    }
}
