# View the most common x509 file types 

view_help() 
{
      cat << EOF_VIEW_HELP
Usage: pki view <file>
 Print the text version x509 certificate or certificate request. 

Options:
 -n, --name <ca name>   No options so far. TODO	
EOF_VIEW_HELP
  return 0
}

#####################################################################

view_cmd() 
{
  local view_opt infile identified=0 view_nopt_arg
  local filetypes="x509 req"
  local informs="PEM DER NET"
  local view_opt_list="l+list"
  local output_options="-text -noout"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $view_opt_list view_opt; then 

      case "$view_opt" in

        # Specify the output file name
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once $OPTARG
	  outfile=$OPTARG
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the file to view 
    else
      argv $OPTIND view_nopt_arg
      if [ -z ${infile+x} ]; then
        infile="$view_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$view_nopt_arg>" 
      fi
    fi

  done

  # No input file, nothing to view
  if [ -z ${infile+x} ]; then
    usage_error "No input file to view"
  else
    is_readable $infile
  fi

  # The outer loop runs through the known file types
  for filetype in $filetypes; do

    # Inner loop runs through all known file formats 
    for inform in $informs; do 
      view_cmd="openssl $filetype -in $infile -inform $inform"
      $view_cmd > /dev/null 2>&1 && { identified=1; break; }
    done
    [ $identified -eq 1 ] && break

  done
 
  # If the file format is identified, output the text 
  # Otherwise throw a runtime errorr 
  if [ $identified -eq 1 ]; then
    $view_cmd $output_options
  else
    runtime_error "Unknown file type"
    return 1
  fi
  return 0
}
