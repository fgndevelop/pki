
#---------------------------------------------------------->
#
#  Shell Script Framework v1.0 library
#
#  sfw_dyn.sh
#  "Dynamically" include required Script Framework libraries 
#
#<----------------------------------------------------------

#
cli="@INSTALL_LIB_DIR@/sfw_cli.sh"				# Script Framework Command Line Interface
lib="@INSTALL_LIB_DIR@/sfw_std.sh"				# Script Framework Standard Library 

# Load each defined library. We can't use "runtime_error()" here, as it is
# part of sfw_err.sh
# Cave: Order of library loading DOES matter.

for sfw_lib in $lib $err $cli; do				
  if [ -f $sfw_lib ]; then
    . $sfw_lib
  else 
   echo "Error: missing library $sfw_lib" >&2
   exit 1
  fi
done
unset sfw_lib err cli lib
