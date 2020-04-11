function ConvertTo-Base64([string] $Content) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    return [System.Convert]::ToBase64String($bytes)
}

function ConvertFrom-Base64([string] $Base64) {
    $bytes = [System.Convert]::FromBase64String($Base64)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}