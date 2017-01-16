# Generate or verify a certificate signing request

req_help()
{
      cat << EOF_REQ_HELP
Usage: pki req [OPTION] <config file>
 Create a certificate signing request (csr) from the information provided
 in <config file>. If no options are given, a sample csr config file is
 printed to stdout. 
 If the provided config file defines a CA, then default filenames for
 private key and csr are derived from the VALUES IN the config file.
 Otherwise, default output filenames are derived from the CONFIG FILENAME.
 An existing keyfile will be used. If no keyfile is present, it will be
 created (RSA 4096bit). 

Options:
 -e, --ecc                  Create an elliptic curve (ECDSA) key instead of the
                              default RSA key
 -w, --windows              By default, the secp256k1 curve will be used when generating
                              an ecc private key. When "windows" is specified, a windows
                              compatible (P-256 i.e. prime256v2) curve is used.
 -u, --unencrypted          The generated private key will not be encrypted (e.g. some
                              servers require unencrypted keys with their certificates) 
 -k, --keyfile <file>       Use <file> as private key to sign the csr. If <file>
                              does not exist, a private key is generated and
                              written to <file>
 -o, --outfile <file>       Write csr to <file>. Use this option to override 
                              the default filename (see above)
 -p, --passphrase <secret>  Encrypt the private key using passphrase <secret> or, if a
                             keyfile is provided, use this passphrase for decryption of
                             the given key. Either way the given passphrase is automatically
                             applied when decrypting the private key for signing the csr
 -v, --verify 	  	    Use this option to verify a SIGNED csr. With this
			     option, the given filename is not considered a 
                             config file but rather a signed csr
EOF_REQ_HELP
  return 0
}

#########################################################################

req_cmd() 
{
  local csr_conf private_key key_explicit=0 key_options ecc=0 windows=0 encrypted=1 outfile verify=0
  local optlist="c:ek:o:p:uv:w+config:+ecc+keyfile:+outfile:+passphrase+unencrypted+verify+windows"
  local req_passphrase req_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in
  
        # This option generates an ecc key instead of the default
        # RSA key
        e|ecc)
          [ $ecc -eq 0 ] || more_than_once "$req_opt" 
          ecc=1
          key_options="${key_options+$key_options | }ecc"
          ;;

        # The keyfile may be defined explicitly
        # We need the key_explicit flag later on to be able to distinguish
        # the two key exists / key specified on cmdline cases
        k|keyfile)
          [ -z ${private_key+x} ] || more_than_once "$req_opts"
          key_explicit=1
          private_key="$OPTARG"
          ;;

        # Specify the output file name
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once "$req_opts"
	  outfile="$OPTARG"
          ;;

        # Provide a passphrase on the cmdline with all the pros and cons
        p|passphrase)
          [ -z ${req_passphrase+x} ] || more_than_once "$req_opts"
          req_passphrase="$OPTARG"
          ;;

        # This option uses a Windows CNG - compatible curve when
        # creating an ecc key
        w|windows)
          [ $windows -eq 0 ] || more_than_once "$req_opts"
          key_options="${key_options+$key_options | }windows-compatible"
          windows=1
          ;;

        # Generate an unencrypted key (e.g. for server certificates)
        u|unencrypted)
          [ $encrypted -eq 1 ] || more_than_once "$req_opts"
          key_options="${key_options+$key_options | }unencrypted"
          encrypted=0
          ;;

        # Verify a request
        v|verify)
          [ $verify -eq 0 ] || more_than_once $OPTARG
	  verify=1
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the config file to use 
    # We only accept one config file, i.e. create one request at a time
    else
      argv $OPTIND req_nopt_arg
      [ -z ${csr_conf+x} ] || usage_error "invalid argument on command line <$csr_nopt_arg>"
      csr_conf="$req_nopt_arg"
      OPTIND=$((OPTIND+1))
    fi

  done

  # If the -v switch was given, it's not a config file but 
  # a signed csr to verify 
  if [ $verify -eq 1 ]; then
    [ -z ${csr_conf+x} ] && usage_error "No csr to verify"

    if openssl req -noout -in $config >/dev/null 2>&1; then
      runtime_msg "Certificate verified."
      return 0
    else
      runtime_msg "Certificate failed verification."
      return 1
    fi
  fi

  # No config file, no signing request
  if [ -z ${csr_conf+x} ]; then
    usage_error "No config file to create a csr"
  # Otherwise we SET "config" and hence from now on we USE $config !
  else
    set_config "$csr_conf" || return 1
  fi

  # If a passphrase was provided, we make sure it's not whitespace only
  if ! [ -z ${req_passphrase+x} ]; then
    case "$req_passphrase" in 
      *[![:space:]]*) : ;; 
      *)  usage_error "the passphrase must not be empty" ;;
    esac
  fi

  # If "ca_name" and "ca_dir" are present in the config file, 
  # it is considered a ca config file
  # File name values are then created from the config file variables

  if get_ca_from_config $config; then

    [ -z ${outfile+x} ] && outfile=$ca_dir/$ca_name.csr
    [ -z ${private_key+x} ] && private_key=$ca_dir/private/$ca_name.key

  # If it's not a ca config file, derive "default_keyfile" from req section
  # or set the default value for the private keyfile name 
  # Derive certificate request filename from the config filename
  else
    
    # Private keyfile name
    [ -z ${private_key+x} ] && private_key=$(awk '/^default_keyfile / { print $3 }' $config)
    [ -z "$private_key" ] && private_key=${config%.*}.key

    # Outfile name
    [ -z ${outfile+x} ] && outfile=${config%.*}.csr

  fi

  # We do not overwrite existing files
  if [ -e "$outfile" ]; then
    runtime_error "won't overwrite existing file: <$outfile>"
    return 1
  fi

  # If the private key does not exist, it will be created now
  if ! [ -e "${private_key}" ]; then

    # If creating a private key fails, that's an error
    # This function is added to avoid redundancy 
    failed_key() { runtime_error "Generating a private key failed"; }

    # Use given key options or set default values 
    [ -z ${key_options+x} ] && key_options="default: RSA 4096bit"

    # Short runtime info
    runtime_msg "Creating private key for certificate request"

    # Generate an ecc key if required
    if [ $ecc -eq 1 -o $windows -eq 1 ]; then

      # For windows compatibility we need to stick to CNG supported curves
      # otherwise we use the curve bitcoin is using, too
      [ $windows -eq 0 ] && curve=secp256k1 || curve=prime256v1 
      if ! gen_ecc_key ${private_key} $curve $encrypted "${req_passphrase-}"; then
        failed_key 
        return 1
      fi

    # By default, a rsa key is generated
    else
      if ! gen_rsa_key ${private_key} $encrypted "${req_passphrase-}"; then
        failed_key 
        return 1
      fi
    fi

  # If a key exists, it will be used. This means that key options are
  # not effective, so if key options were given this is probably not 
  # what the user wants, hence we exit with error
  else
    if [ $windows -eq 1 -o $ecc -eq 1 -o $encrypted -eq 0 ]; then
      runtime_error "no key options allowed when using existing keyfile"
      return 1
    fi
    key_options="Using existing key"
  fi
    
  # Print some diagnostics
  echo "Config file: 	<$config>"
  echo "Private key:	<$private_key>"
  echo "Key options: 	<$key_options>"
  echo "Output file: 	<$outfile>"

  # Create the CSR and write it to $outfile
  # If a passphrase was provided, it's added to the command
  if run_openssl $outfile req -new -config $config -key $private_key \
                 "${req_passphrase+-passin pass:$req_passphrase}"; then
    return 0
  else
    return 1
  fi
}
