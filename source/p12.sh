# Generate a pkcs12-file 

p12_help()
{
      cat << EOF_PKCS12_HELP
Usage: pki p12 [options] <file>
  Create a pkcs12 container to export a certificate <file> with its
  corresponding private key (plus an optional certificate chain of trust).
 
Options:
 -f, --force           An existing output file (see "outfile" below) is not over-
	                 written by default. Use this option to enforce overwriting. 
 -i, --include <file>  By default, no certificate chain is included. Use this
   		         option to add a certificate (or many certificates bundled
		         in a single file) to the pkcs12 container. To bundle 
			 certificates in a file use the following command:
                         "cat cert1 cert2 ... certX > bundle"
 -k, --keyfile <file>  The default keyfile name is derived from the main input file.
			 If this does not work, use -k to specify the keyfile name.
 -o, --outfile <file>  Specify the output file [default="ca_name".p12]	
		         Use this option if you want to explicitly specify
		         the filename of the pkcs12 file that will be output.
		         By default, the output filename will be derived from
		         the config file basename.
EOF_PKCS12_HELP
  return 0
}

###################################################################################

p12_cmd() 
{
  local basename certfile keyfile outfile include force=0
  local p12_run_cmd p12_nopt_arg
  local optlist="fi:k:o:+force+include:+keyfile:+outfile:"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist p12_opt; then 

      case "$p12_opt" in

        # Force overwriting existing files
        f|force)
          [ $force -eq 0 ] || more_than_once $p12_opt 
          force=1
          ;;

        # Specify a file with certificates that should be included
        i|include) 
          [ -z ${include+x} ] || more_than_once $p12_opt 
	  include="$OPTARG"
          ;;

        # Specify the keyfile, if the default does not work 
        k|keyfile)
          [ z ${keyfile+x} ] || more_than_once $OPTARG
          keyfile="$OPTARG"
          ;;

        # Specify the output file
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once $OPTARG
	  outfile="$OPTARG"
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # This command does not allow non-option arguments so far
    else
      argv $OPTIND p12_nopt_arg
      if [ -z ${certfile+x} ]; then
        certfile="$p12_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$p12_nopt_arg>" 
      fi
    fi
  done

  # You want a SafeBag (pkcs12 container) ? Give me some input...
  [ -z ${certfile+x} ] && usage_error "Certificate file not specified"

  # Derive filenames if necessary
  basename=${certfile%.*}
  [ -z ${keyfile+x} ] && keyfile=${basename}.key

  # check if files are readable
  for file in "${include-}" "${keyfile-}"; do
    if ! is_readable "$file"; then
      runtime_error "cannot read <$file>"
      return 1
    fi
  done

  # The outfile will be placed in the current directory, NOT in the
  # absolute directory of the certificate
  [ -z ${outfile+x} ] && outfile="${basename##*/}.p12"
  
  # Are you sure to overwrite existing files ?
  if [ -e $outfile ]; then
    if ! [ $force -eq 1 ]; then
      runtime_error 'file exists: <$outfile> Use "-f" to overwrite'
      return 1
    fi
  fi

  # Output diagnostics: 
  echo "Certificate:	    <$certfile>"
  echo "Keyfile:	    <$keyfile>"
  echo "Included certs in:  <${include--}>"
  echo "Output file: 	    <$outfile>"
  echo

  # All options are set, now pack the pkcs12 container 
  p12_run_cmd="pkcs12 -export -in $certfile -inkey $keyfile ${include+-certfile $include}"
  run_openssl $outfile $p12_run_cmd && return 0 || return 1
}
