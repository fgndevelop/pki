# This function generates a plain "old" rsa key in KEYFILE_NAME.
# The key will be encrypted when the first optional argument is set to 1
# If the key is encrypted, you can supply a second optional argument
# which will be considered the passphrase to use for encryption 
#
# Usage: gen_rsa_key <KEYFILE_NAME> [0|1] [
# Returns:
# 0 on success
# 1 on error

gen_rsa_key() 
{
  local keyfile cipher_param pass_phrase

  # Argument check
  [ -z ${1+x} ] && debug "gen_rsa_key(): missing argument to function call"
  keyfile=$1

  # The encryption argument is optional, if nothing is specified we go
  # with the openssl default
  if ! [ -z ${2+x} ]; then

    # If encryption is requested, we also check for a passphrase
    if [ $2 -eq 1 ]; then
      cipher_param="-aes-128-cbc"
      [ -z ${3:+x} ] || pass_phrase="-pass pass:$3"
    fi

  fi

  # Set parameters for run_openssl()
  genkey_cmd="genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 \
              ${cipher_param-} ${pass_phrase-}"

  # Generate the key and return
  run_openssl $keyfile $genkey_cmd && return 0 || return 1
}

# This function generates a key using elliptic curve cryptographic algorithms
# 
# https://blog.cloudflare.com/a-relatively-easy-to-understand-primer-on-elliptic-curve-cryptography/
# tells us why elliptic curve cryptography is a good idea 
#
# See https://wiki.openssl.org/index.php/Elliptic_Curve_Cryptography#Named_Curves
# for why it has to be "named_curve"
#
# See https://en.bitcoin.it/wiki/Secp256k1 for the choice of curve when the system supports it
#
# See https://msdn.microsoft.com/en-us/library/windows/desktop/bb204778%28v=vs.85%29.aspx
# for the list of curves that the "Microsoft Cryptography Next Generation" (CNG) API supports:
# prime256v1, secp384r1, and secp521r1
#
# Usage: gen_ecc_key <KEYFILE_NAME> <PRIME> [0|1] [passphrase]
# Returns:
# 0 on success
# 1 on failure

gen_ecc_key() 
{
  local keyfile curve cipher_param retval pass_phrase
  
  # Arg check
  [ $# -lt 2 ] && debug "missing argument to function call: gen_ecc_key()"
  keyfile=$1
  curve=$2

  # Encryption is an optional argument
  if ! [ -z ${3+x} ]; then
    # If encryption is requested, we also check for a passphrase
    if [ $3 -eq 1 ]; then
      cipher_param="-aes-128-cbc"
      [ -z ${4:+x} ] || pass_phrase="-pass pass:$4"
    fi
  fi

  # We generate parameters seperately 
  curve_cmd="ecparam -name $curve -param_enc named_curve -genkey"
  if run_openssl "${keyfile}.ecparam" "$curve_cmd"; then

    # because only then we can choose to encrypt the key (or not)
    genkey_cmd="genpkey -paramfile ${keyfile}.ecparam ${cipher_param-} ${pass_phrase-}"
    if run_openssl $keyfile $genkey_cmd; then
      rm ${keyfile}.ecparam
      return 0
    else
      runtime_error "failed to generate key from ec parameters"
      return 1
    fi

  else
    runtime_error "failed to generate ec parameters for key"
    return 1
  fi
}
