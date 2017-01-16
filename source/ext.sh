# Generate a pkcs12-file 
ext() 
{
  local configfile
#  local ext_optlist="fi:k:o:+force+include:+keyfile:+outfile:"

 # # parse the command line for specific settings
 # while [ $OPTIND -le $argc ]; do

 #   if getopts $optlist p12_opt; then 

 #     case "$p12_opt" in

 #       # Force overwriting existing files
 #       f|force)
 #         [ $force -eq 0 ] || more_than_once $OPTARG
 #         force=1
 #         ;;

 #       # Missing argument to option, invalid option
 #       ":") missing_argument $OPTARG ;;
 #       "?") invalid_option ;; 
 #          
 #     esac

 #   # This command does not allow non-option arguments so far
 #   else
 #     if [ -z ${certfile+x} ]; then
 #       certfile=$(argv $OPTIND)
 #       OPTIND=$((OPTIND+1))
 #     else
 #       usage_error "invalid argument ..." 
 #     fi
 #   fi
 # done

 # If a directory was given, assume there's a config file in that 
 # directory
 configfile=$(argv 1)
 if [ -d $configfile ]; then 
   configfile="${configfile}/config"
 fi

 egrep "^ *\[.*ext.*\]" "$configfile"

 return 0

}
