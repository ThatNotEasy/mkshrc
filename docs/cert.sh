#!/bin/env sh

tmp_path='/data/local/tmp'
crt_path="$tmp_path/http-toolkit-ca-certificate.crt"

# Check if certificate file exists
[ ! -f "$crt_path" ] && {
  echo "Certificate file not found: $crt_path" >&2
  exit 1
}

# Convert line endings if dos2unix is available
if command -v dos2unix >/dev/null 2>&1; then
  dos2unix "$crt_path"
fi

# Generate certificate hash and create hash file
crt_hash="$(openssl x509 -inform PEM -subject_hash_old -in "$crt_path" -noout 2>/dev/null)" || {
  echo "Failed to generate certificate hash" >&2
  exit 1
}

hash_path="$tmp_path/$crt_hash.0"

# Create the certificate file with proper format
openssl x509 -in "$crt_path" >"$hash_path" 2>/dev/null || {
  echo "Failed to create certificate file" >&2
  exit 1
}

openssl x509 -in "$crt_path" -fingerprint -text -noout >>"$hash_path" 2>/dev/null || {
  echo "Failed to append certificate details" >&2
  exit 1
}
