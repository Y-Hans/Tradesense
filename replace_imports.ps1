$files = Get-ChildItem -Path "lib" -Recurse -Filter *.dart | Where-Object { $_.Name -ne 'crypto_loading_indicator.dart' }
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'CryptoLoadingIndicator') {
        if ($content -notmatch 'crypto_loading_indicator.dart') {
            $content = $content.Replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';")
            Set-Content -Path $f.FullName -Value $content -Encoding utf8
            Write-Host "Added import to "
        }
    }
}
