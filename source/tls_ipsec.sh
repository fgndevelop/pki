# Output a TLS / IPSEC server or client request file which
# can then be edited and signed by a signing ca

tls_ipsec_help()
{
      cat << EOF_TLS_IPSEC_HELP
Usage: pki server [options] <file>
  Create a generic, TLS/IPSec certificate signing request

Options:
 -c, --client		Generate a client csr [default=server csr]

EOF_TLS_IPSEC_HELP
  return 0
}

########################################################################

tls_ipsec_cmd() 
{
  local req_name encrypt_key ext_usage client_req=0 san
  local optlist="c+client" tls_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in

        # Specify the output file
        c|client)
          [ $client_req -eq 0 ] || more_than_once $OPTARG
	  client_req=1 
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # the actual certificate request name is a non-option argument
    else
      argv $OPTIND tls_nopt_arg
      if [ -z ${req_name+x} ]; then
        req_name="$tls_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$tls_nopt_arg>" 
      fi
    fi
  done

  # We need a filename for the server request
  [ -z ${req_name+x} ] && usage_error "Certificate signing request name not specified"

  # We do not want to overwrite existing certificates 
  [ -e $req_name ] && runtime_error "file already exists: <$req_name>"

  # Set client / server extended key Usage
  if [ $client_req -eq 0 ]; then
    encrypt_key="no"
    ext_usage="serverAuth"
    san="DNS:sample.uri.org"
  else
    encrypt_key="yes"
    ext_usage="clientAuth"
    san="email:peer@sample.uri.org"
  fi
  
  echo "TLS/IPSec Server Request:	<$req_name>"
  echo "Extended Key Usage:		<$ext_usage>"

  # Write the server certificate signing request config file to $server
  # and modify it to match the given name
  cat_tls_ipsec_request_conf | \
  sed \
  -e "s|@KEYFILE@|${req_name%.*}.key|g" \
  -e "s/@ENCRYPT_KEY@/$encrypt_key/g" \
  -e "s/@EXTENDED_KEY_USAGE@/$ext_usage/g" \
  -e "s/@SAN@/$san/g" \
  > $req_name

  return 0
}
