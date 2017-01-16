# Output a certificate signing request whose intended usage is
# as a peer- or server-certificate in EAP-TLS

eap_tls_help()
{
      cat << EOF_EAP_TLS_HELP
Usage: pki eap-tls [options] <name>
  Create a client or server certificate request configuration file <name>
  for certificates used during EAP-TLS handshakes in e.g. wireless LANs.
  (In EAP-TLS terminology the client is called "peer")

Options:
 -c, --client	The certificate configuration will be customized
		 for a "peer_id" (default is "server_id")	
 -l, --legacy	By default, an ECC-key will be created for the certificate
		  which will be used automatically by the "req" command.
		  The legacy-option disables the key creation which effectively
		  means that when running the "req" command, the default 4096-bit
		  RSA key will be created with the certificate signing request. 
 -w, --windows	If the certificate will be used by a Windows client, this option
                  will generate the ECC-key using a NIST-approved curve which is 
                  suitable for the Windows CNG crypto api.
EOF_EAP_TLS_HELP
  return 0
}

##########################################################################

eap_tls_cmd() 
{
  local req_name keyfile encrypt_key=0 ext_usage legacy=0 client_req=0 cng=0 san
  local optlist="clw+client+legacy+windows" req_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in

        # generate a peer_id certificate 
        c|client)
          [ $client_req -eq 0 ] || more_than_once "$req_opt"
	  client_req=1 
          ;;

        # generate the legacy rsa key instead of a modern ecdsa key
        l|legacy)
          [ $legacy -eq 0 ] || more_than_once "$req_opt"
          legacy=1
          ;;

        # request generation of a key usable by the Windows CNG 
        w|windows)
          [ $cng -eq 0 ] || more_than_once "$req_opt"
          cng=1
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # the actual certificate request name is a non-option argument
    else
      argv $OPTIND req_nopt_arg
      if [ -z ${req_name+x} ]; then
        req_name="${req_nopt_arg}.conf"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$req_nopt_arg>"
      fi
    fi
  done

  # You cannot have both legacy AND windows compatibility
  if [ $cng -eq 1 -a $legacy -eq 1 ]; then
    usage_error "Legacy option not compatible with Windows option"
  fi

  # We need a filename for the request
  [ -z ${req_name+x} ] && usage_error "Certificate signing request name not specified"

  # We do not want to overwrite existing certificates 
  if [ -e $req_name ]; then
    runtime_error "file already exists: <$req_name>"
    return 1
  fi

  # If the legacy key is not requested, an ecdsa key will be created
  # By default we use the secp256k1 curve, which is good enough for BitCoin, too
  # If -w / windows is required, we have to use one of the curves supported by
  # the Windows crypto API, see main.sh / gen_cng_ecc_key() for details
  # We generate the parameters first, then the key so we can encrypt 
  keyfile=${req_name%.*}.key
  if [ $legacy -eq 0 ]; then

    if [ -e $keyfile ]; then
      echo "Not creating private key (file exists)"
    else 
      # If it's not a server request, we encrypt the key
      [ $client_req -eq 1 ] && encrypt_key=1
      if [ $cng -eq 1 ]; then
        echo "[ Generating ecdsa key using prime256v1 elliptic curve algorithm ]"
        gen_cng_ecc_key $keyfile $encrypt_key
      else
        echo "[ Generating ecdsa key using sec256k1 elliptic curve algorithm ]"
        gen_ecc_key $keyfile secp256k1 $encrypt_key
      fi
    fi
  fi

  # Set client / server extended key Usage
  if [ $client_req -eq 0 ]; then
    encrypt_key="no"
    identity="server_id"
    ext_usage="serverAuth" 
    san="DNS:sample.uri.org"
  else
    encrypt_key="yes"
    identity="peer_id"
    ext_usage="clientAuth"
    san="email:peer@sample.uri.org"
  fi
 
  # Print some diagnostics 
  echo "EAP-TLS Certificate Request:	<$req_name>"
  echo "Extended Key Usage:		<$ext_usage>"
  echo "EAP Identity:		        <$identity>"
  echo "SAN Type:			<$san>"

  # Write the server certificate signing request config file to $server
  # and modify it to match the given name
  cat_eap_tls_request_conf | \
  sed \
  -e "s|@KEYFILE@|$keyfile|g" \
  -e "s/@ENCRYPT_KEY@/$encrypt_key/g" \
  -e "s/@IDENTITY@/$identity/g" \
  -e "s/@EXTENDED_KEY_USAGE@/$ext_usage/g" \
  -e "s|@SAN@|$san|g" \
  > $req_name

  return 0
}
