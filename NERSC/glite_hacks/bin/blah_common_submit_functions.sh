#!/bin/bash
#  File:     blah_common_submit_functions.sh 
#
#  Author:   Francesco Prelz 
#  e-mail:   Francesco.Prelz@mi.infn.it
#
#
# Copyright (c) Members of the EGEE Collaboration. 2004. 
# See http://www.eu-egee.org/partners/ for details on the copyright
# holders.  
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#     http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License.
#

. `dirname $0`/blah_load_config.sh

#
# Functions to handle the file mapping tables
#

function bls_fl_add_value ()
{
#
# Usage: bls_fl_add_value container_name local_file remote_file
# inserts into a scalar shell-variable based container a new pair of string values
#
  local container_name
  local local_file_name
  local remote_file_name

  container_name=${1:?"Missing container name argument to bls_fl_add_value"}
  local_file_name=${2:?"Missing local file name argument to bls_fl_add_value"}
  remote_file_name=${3:?"Missing remote file name argument to bls_fl_add_value"}

  local last_argument
  local transfer_file

  eval "last_argument=\${bls_${container_name}_counter:=0}"
  eval "bls_${container_name}_local_${last_argument}=\"$local_file_name\""
  eval "bls_${container_name}_remote_${last_argument}=\"$remote_file_name\""
  if [ -n "$4" ]; then
    eval "bls_${container_name}_workname_${last_argument}=\"$4\""
  fi

  eval "let bls_${container_name}_counter++"
}

function bls_fl_subst ()
{
#
# Usage: bls_fl_subst container_name index template_string
# substitutes the value pair at the index'th position in container_name
# to the @@F_LOCAL, @@F_REMOTE and @@F_WORKNAME strings in template_string 
# Result is returned in $bls_fl_subst_result.
#
  local container_name
  local container_index
  local subst_template
 
  container_name=${1:?"Missing container name argument to bls_fl_subst"}
  container_index=${2:?"Missing index to bls_fl_subst"}
  subst_template=${3:?"Missing template bls_fl_subst"}

  local f_local
  local f_remote
  local temp1_result
  local temp2_result
  
  eval "f_local=\"\${bls_${container_name}_local_${container_index}}\""
  eval "f_remote=\"\${bls_${container_name}_remote_${container_index}}\""
  eval "f_workname=\"\${bls_${container_name}_workname_${container_index}}\""

  if [ -z "$f_workname" ]; then
    f_workname="$f_remote"
  fi

  bls_fl_subst_result=""

  if [ \( ! -z "$f_local" \) -a \( ! -z "$f_remote" \) ] ; then
      temp1_result=${subst_template//@@F_LOCAL/$f_local}
      temp2_result=${temp1_result//@@F_WORKNAME/$f_workname}
      bls_fl_subst_result=${temp2_result//@@F_REMOTE/$f_remote}
  fi
}

function bls_fl_subst_and_accumulate ()
{
#
# Usage: bls_fl_subst_and_accumulate container_name template_string separator
# substitutes all the value pairs in container_name
# to the @@F_LOCAL, @@F_REMOTE and @@F_WORKNAME strings in template_string, and
# concatenates the results,separating them with the 'separator' string.
# Result is returned in $bls_fl_subst_and_accumulate_result.
#
  local container_name
  local subst_template
  local separator

  container_name=${1:?"Missing container name argument to bls_fl_subst_and_accumulate"}
  subst_template=${2:?"Missing template argument to bls_fl_subst_and_accumulate"}
  separator=${3:?"Missing separator argument to bls_fl_subst_and_accumulate"}

  bls_fl_subst_and_accumulate_result=""

  local last_argument

  eval "last_argument=\${bls_${container_name}_counter:=0}"

  local ind
  local l_sepa

  l_sepa=""
  
  for (( ind=0 ; ind < $last_argument ; ind++ )) ; do
      bls_fl_subst $container_name $ind "$subst_template"
      if [ ! -z "$bls_fl_subst_result" ] ; then
          bls_fl_subst_and_accumulate_result="${bls_fl_subst_and_accumulate_result}${l_sepa}${bls_fl_subst_result}"
          l_sepa=$separator
      fi
  done
}

function bls_fl_subst_and_dump ()
{
#
# Usage: bls_fl_subst_and_dump container_name template_string filename
# substitutes all the value pairs in container_name
# to the @@F_LOCAL, @@F_REMOTE and @@F_WORKNAME strings in template_string, and
# appends the results as single lines to $filename 
#
  local container_name
  local subst_template
  local filename

  container_name=${1:?"Missing container name argument to bls_fl_subst_and_dump"}
  subst_template=${2:?"Missing template argument to bls_fl_subst_and_dump"}
  filename=${3:?"Missing filename argument to bls_fl_subst_and_dump"}

  local last_argument

  eval "last_argument=\${bls_${container_name}_counter:=0}"

  local ind
  local f_remote
  
  for (( ind=0 ; ind < $last_argument ; ind++ )) ; do
      bls_fl_subst $container_name $ind "$subst_template"
      if [ ! -z "$bls_fl_subst_result" ] ; then
          echo $bls_fl_subst_result >> $filename
      fi
  done
}

function bls_fl_subst_relative_paths_and_dump ()
{
#
# Usage: bls_fl_subst_relative_paths_and_dump container_name template_string filename
# substitutes only the value pairs in container_name where the remote file path 
# doesn't begin with '/' (relative paths).
# to the @@F_LOCAL and @@F_REMOTE strings in template_string, and
# appends the results as single lines to $filename 
#
  local container_name
  local subst_template
  local filename
  local destination_root

  container_name=${1:?"Missing container name argument to bls_fl_subst_relative_paths_and_dump"}
  subst_template=${2:?"Missing template argument to bls_fl_subst_relative_paths_and_dump"}
  filename=${3:?"Missing filename argument to bls_fl_subst_relative_paths_and_dump"}
  destination_root=$4

  local last_argument

  eval "last_argument=\${bls_${container_name}_counter:=0}"

  local ind
  
  for (( ind=0 ; ind < $last_argument ; ind++ )) ; do
      eval "f_workname=\"\${bls_${container_name}_workname_${ind}}\""
      eval "f_remote=\"\${bls_${container_name}_remote_${ind}}\""

      if [ -n "$destination_root" ]; then
        if [ "${f_remote:0:1}" != "/" ]; then
            if [ -z "$f_workname" ]; then
                eval "bls_${container_name}_workname_${ind}=\"$f_remote\""
            fi
            eval "bls_${container_name}_remote_${ind}=\"${destination_root}/$f_remote\""
        fi
      fi

      if [ -z "$f_workname" ]; then
          f_workname="$f_remote"
      fi

      if [ "${f_workname:0:1}" != "/" ]; then
          bls_fl_subst $container_name $ind "$subst_template"
          if [ ! -z "$bls_fl_subst_result" ] ; then
              echo $bls_fl_subst_result >> $filename
          fi
      fi
  done
}

function bls_fl_clear ()
{
#
# Usage: bls_fl_clear container_name 
# Deletes all the values in container container_name.
#
  local container_name

  container_name=${1:?"Missing container name argument to bls_fl_clear"}

  local last_argument

  eval "last_argument=\${bls_${container_name}_counter:=0}"

  local ind
  
  for (( ind=0 ; ind < $last_argument ; ind++ )) ; do
     eval "unset bls_${container_name}_local_${ind}"
     eval "unset bls_${container_name}_workname_${ind}"
     eval "unset bls_${container_name}_remote_${ind}"
  done

  eval "unset bls_${container_name}_counter"
}

function bls_parse_submit_options ()
{
  usage_string="Usage: $0 -c <command> [-i <stdin>] [-o <stdout>] [-e <stderr>] [-x <x509userproxy>] [-v <environment>] [-s <yes | no>] [-- command_arguments]"

  bls_opt_stgcmd="yes"
  bls_opt_stgproxy="yes"
  
  if [ "x$blah_wn_proxy_renewal_daemon" == "x" ]
  then
    bls_proxyrenewald="${blah_bin_directory}/BPRserver"
  else
    bls_proxyrenewald="$blah_wn_proxy_renewal_daemon"
  fi
  
  #default is to stage proxy renewal daemon 
  bls_opt_proxyrenew="yes"
  
  if [ ! -r "$bls_proxyrenewald" ]
  then
      bls_opt_proxyrenew="no"
  fi
  
  bls_proxy_dir=~/.blah_jobproxy_dir
  
  bls_opt_workdir=$PWD

  #default values for polling interval and min proxy lifetime
  bls_opt_prnpoll=30
  bls_opt_prnlifetime=0
  
  bls_BLClient="${blah_bin_directory}/BLClient"
  
  ###############################################################
  # Parse parameters
  ###############################################################
  while getopts "a:i:o:e:c:s:v:V:dw:q:n:N:z:h:S:r:p:l:x:u:j:T:I:O:R:C:D:m:" arg 
  do
      case "$arg" in
      a) bls_opt_xtra_args="$OPTARG" ;;
      i) bls_opt_stdin="$OPTARG" ;;
      o) bls_opt_stdout="$OPTARG" ;;
      e) bls_opt_stderr="$OPTARG" ;;
      v) bls_opt_envir="$OPTARG";;
      V) bls_opt_environment="$OPTARG";;
      c) bls_opt_the_command="$OPTARG" ;;
      s) bls_opt_stgcmd="$OPTARG" ;;
      d) bls_opt_debug="yes" ;;
      w) bls_opt_workdir="$OPTARG";;
      q) bls_opt_queue="$OPTARG";;
      n) bls_opt_mpinodes="$OPTARG";;
      N) bls_opt_hostsmpsize="$OPTARG";;
      z) bls_opt_wholenodes="$OPTARG";;
      h) bls_opt_hostnumber="$OPTARG";;
      S) bls_opt_smpgranularity="$OPTARG";;
      r) bls_opt_proxyrenew="$OPTARG" ;;
      p) bls_opt_prnpoll="$OPTARG" ;;
      l) bls_opt_prnlifetime="$OPTARG" ;;
      x) bls_opt_proxy_string="$OPTARG" ;;
      u) bls_opt_proxy_subject="$OPTARG" ;;
      j) bls_opt_creamjobid="$OPTARG" ;;
      T) bls_opt_temp_dir="$OPTARG" ;;
      I) bls_opt_inputflstring="$OPTARG" ;;
      O) bls_opt_outputflstring="$OPTARG" ;;
      R) bls_opt_outputflstringremap="$OPTARG" ;;
      C) bls_opt_req_file="$OPTARG";;
      D) bls_opt_run_dir="$OPTARG";;
      m) bls_opt_req_mem="$OPTARG";;
      -) break ;;
      ?) echo $usage_string
         exit 1 ;;
      esac
  done

# Command is mandatory
  if [ "x$bls_opt_the_command" == "x" ]
  then
      echo $usage_string
      exit 1
  fi

# Make sure we can survive without a proxy
  if [ "x$bls_opt_proxy_string" == "x" ]
  then
      bls_opt_proxyrenew="no"
      bls_opt_stgproxy="no"
  fi

  bls_opt_proxyrenew_numeric=0
  if [ "x$bls_opt_proxyrenew" == "xyes" ] ; then
      bls_opt_proxyrenew_numeric=1
  fi

  shift `expr $OPTIND - 1`
  bls_arguments=$*
}

function bls_test_shared_dir ()
{
  local file_name
  local test_dir 
  local shared_dir_list

  file_name=${1:?"Missing file name argument to bls_test_shared_dir"}

  bls_is_in_shared_dir="no"

# Test only absolute paths
  if [ "${file_name:0:1}" != "/" ] ; then
      return
  fi

  shared_dir_list="$blah_shared_directories"
  test_dir=""

  until [ "$shared_dir_list" == "$test_dir" ]; do
    test_dir=${shared_dir_list%%:*}
    shared_dir_list=${shared_dir_list#*:}
    if [ "${file_name:0:${#test_dir}}" == "$test_dir" ]; then
      bls_is_in_shared_dir="yes"
      break
    fi
  done 
}

function bls_setup_all_files ()
{

# Make sure /dev/null is always 'shared' (i.e., not copied over by the
# batch system).

  if [ -z "$blah_shared_directories" ]; then
      blah_shared_directories="/dev/null"
  else
      bls_test_shared_dir "/dev/null"
      if [ "x$bls_is_in_shared_dir" != "xyes" ] ; then
         blah_shared_directories="$blah_shared_directories:/dev/null"
      fi   
  fi

  if [ -z "$blah_wn_inputsandbox" ]; then
#     Backwards compatibility with old name.
      blah_wn_inputsandbox="$blahpd_inputsandbox"
  fi
  if [ -z "$blah_wn_outputsandbox" ]; then
#     Backwards compatibility with old name.
      blah_wn_outputsandbox="$blahpd_outputsandbox"
  fi

  local last_char_pos

  if [ -n "$blah_wn_inputsandbox" ]; then
      last_char_pos=$(( ${#blah_wn_inputsandbox} - 1 ))
      if [ "${blah_wn_inputsandbox:$last_char_pos:1}" != "/" ]; then
         blah_wn_inputsandbox="${blah_wn_inputsandbox}/"
      fi
  fi
  if [ -n "$blah_wn_outputsandbox" ]; then
      last_char_pos=$(( ${#blah_wn_outputsandbox} - 1 ))
      if [ "${blah_wn_outputsandbox:$last_char_pos:1}" != "/" ]; then
         blah_wn_outputsandbox="${blah_wn_outputsandbox}/"
      fi
  fi

  curdir=`pwd`
  if [ -z "$bls_opt_temp_dir"  ] ; then
      bls_opt_temp_dir="$curdir"
  else
      if [ ! -e $bls_opt_temp_dir ] ; then
          mkdir -p $bls_opt_temp_dir
      fi
      if [ ! -d $bls_opt_temp_dir -o ! -w $bls_opt_temp_dir ] ; then
          echo "1ERROR: unable to create or write to $bls_opt_temp_dir"
          exit 0
      fi
  fi
  
  
  # Get a suitable name for temp file
  if [ "x$bls_opt_debug" != "xyes" ]
  then
      if [ ! -z "$bls_opt_creamjobid"  ] ; then
          if [ $bls_opt_creamjobid == ${bls_opt_creamjobid%*_*} ] ; then 
             bls_tmp_name="cream_${bls_opt_creamjobid}"
          else
              bls_tmp_name=${bls_opt_creamjobid}
          fi 
          bls_tmp_file="$bls_opt_temp_dir/$bls_tmp_name"
      else
          rand=`od -A n -t xC -N 6 /dev/urandom`
          bls_tmp_name=bl_${rand// /}
          bls_tmp_file="$bls_opt_temp_dir/$bls_tmp_name"
          `touch $bls_tmp_file;chmod 600 $bls_tmp_file`
      fi
      if [ $? -ne 0 ]; then
          echo Error
          exit 1
      fi
  else
      # Just print to /dev/tty if in debug
      bls_tmp_file="/dev/tty"
  fi
  
  # Set up temp file name for requirement passing
  if [ ! -z $bls_opt_req_file ] ; then
     bls_opt_tmp_req_file=${bls_opt_req_file}-temp_req_script
  else
     bls_opt_tmp_req_file=`mktemp $bls_opt_temp_dir/temp_req_script_XXXXXXXXXX` 
  fi

  # Create unique extension for filenames
  uni_uid=`id -u`
  uni_pid=$$
  uni_time=`date +%s`
  uni_ext=$uni_uid.$uni_pid.$uni_time
  
  # Put executable into inputsandbox (unless in a shared dir)
  bls_test_shared_dir "$bls_opt_the_command"
  if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
      bls_opt_stgcmd="no"
  fi  

  if [ "x$bls_opt_stgcmd" == "xyes" ] ; then
      bls_command_basename="`basename $bls_opt_the_command`"
      bls_fl_add_value inputsand "$bls_opt_the_command" "${blah_wn_inputsandbox}${bls_command_basename}.$uni_ext" "$bls_command_basename"
  fi
  
  # Put BPRserver into sandbox
  if [ "x$bls_opt_proxyrenew" == "xyes" ] ; then
      if [ -r "$bls_proxyrenewald" ] ; then
          bls_test_shared_dir "$bls_proxyrenewald"
          if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
              remote_BPRserver="$bls_proxyrenewald"
          else
              remote_BPRserver=`basename $bls_proxyrenewald`.$uni_ext
              bls_fl_add_value inputsand "$bls_proxyrenewald" "${blah_wn_inputsandbox}${remote_BPRserver}" "$remote_BPRserver"
              remote_BPRserver="./$remote_BPRserver"
          fi
      else
          bls_opt_proxyrenew="no"
      fi
  fi
  
  # Setup proxy transfer
  bls_need_to_reset_proxy=no
  bls_proxy_remote_file=
  if [ "x$bls_opt_stgproxy" == "xyes" ] ; then
      bls_proxy_local_file=${bls_opt_workdir}"/"`basename "$bls_opt_proxy_string"`;
      [ -r "$bls_proxy_local_file" -a -f "$bls_proxy_local_file" ] || bls_proxy_local_file="$bls_opt_proxy_string"
      [ -r "$bls_proxy_local_file" -a -f "$bls_proxy_local_file" ] || bls_proxy_local_file=/tmp/x509up_u`id -u`
      if [ -r "$bls_proxy_local_file" -a -f "$bls_proxy_local_file" ] ; then
          bls_proxy_remote_file=${bls_tmp_name}.proxy
          bls_test_shared_dir "$bls_proxy_local_file"
          if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
            bls_fl_add_value inputcopy "$bls_proxy_local_file" "${bls_proxy_remote_file}"
          else
            bls_fl_add_value inputsand "$bls_proxy_local_file" "${blah_wn_inputsandbox}${bls_proxy_remote_file}" "$bls_proxy_remote_file"
          fi
          bls_need_to_reset_proxy=yes
      fi
  fi
  
  # Setup stdin, stdout & stderr
  if [ ! -z "$bls_opt_stdin" ] ; then
      if [ "${bls_opt_stdin:0:1}" != "/" ] ; then bls_opt_stdin=${bls_opt_workdir}/${bls_opt_stdin} ; fi
      if [ -f "$bls_opt_stdin" ] ; then
          bls_test_shared_dir "$bls_opt_stdin"
          if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
              bls_arguments="$bls_arguments < \"$bls_opt_stdin\""
          else
              bls_unique_stdin_name=`basename $bls_opt_stdin`.$uni_ext
              bls_fl_add_value inputsand "$bls_opt_stdin" "${blah_wn_inputsandbox}${bls_unique_stdin_name}" "$bls_unique_stdin_name"
              bls_arguments="$bls_arguments < \"$bls_unique_stdin_name\""
          fi
      else
          bls_arguments="$bls_arguments < \"$bls_opt_stdin\""
      fi
  fi
  if [ ! -z "$bls_opt_stdout" ] ; then
      if [ "${bls_opt_stdout:0:1}" != "/" ] ; then bls_opt_stdout=${bls_opt_workdir}/${bls_opt_stdout} ; fi
      bls_test_shared_dir "$bls_opt_stdout"
      if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
          bls_arguments="$bls_arguments > \"$bls_opt_stdout\""
      else
          bls_unique_stdout_name="${blah_wn_outputsandbox}out_${bls_tmp_name}_`basename $bls_opt_stdout`"
          bls_arguments="$bls_arguments > \"$bls_unique_stdout_name\""
          bls_fl_add_value outputsand "$bls_opt_stdout" "$bls_unique_stdout_name"
      fi
  fi
  if [ ! -z "$bls_opt_stderr" ] ; then
      if [ "${bls_opt_stderr:0:1}" != "/" ] ; then bls_opt_stderr=${bls_opt_workdir}/${bls_opt_stderr} ; fi
      bls_test_shared_dir "$bls_opt_stderr"
      if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
          bls_arguments="$bls_arguments 2> \"$bls_opt_stderr\""
      else
          if [ "$bls_opt_stderr" == "$bls_opt_stdout" ]; then
              bls_arguments="$bls_arguments 2>&1"
          else
              bls_unique_stderr_name="${blah_wn_outputsandbox}err_${bls_tmp_name}_`basename $bls_opt_stderr`"
              bls_arguments="$bls_arguments 2> \"$bls_unique_stderr_name\""
              bls_fl_add_value outputsand "$bls_opt_stderr" "$bls_unique_stderr_name"
          fi
      fi
  fi

#Add to inputsand files to transfer to execution node
#absolute paths
  local xfile
  local xfile_base

  if [ ! -z "$bls_opt_inputflstring" ] ; then
      exec 4< "$bls_opt_inputflstring"
      while read xfile <&4 ; do
          if [ ! -z $xfile  ] ; then
               if [ "${xfile:0:1}" != "/" ] ; then xfile=${bls_opt_workdir}/${xfile} ; fi
               bls_test_shared_dir "$xfile"
               if [ "x$bls_is_in_shared_dir" == "xyes" ] ; then
                   bls_fl_add_value inputcopy "$xfile" "./`basename ${xfile}`"
               else
                   xfile_base="`basename ${xfile}`"  
                   bls_fl_add_value inputsand "$xfile" "${blah_wn_inputsandbox}${xfile_base}.$uni_ext" "${xfile_base}"
               fi
          fi
      done
      exec 4<&-
  fi

  xfile=
  local xfileremap

#Add files to transfer from execution node
  if [ ! -z "$bls_opt_outputflstring" ] ; then
      exec 5< "$bls_opt_outputflstring"
      if [ ! -z "$bls_opt_outputflstringremap" ] ; then
          exec 6< "$bls_opt_outputflstringremap"
      fi
      while read xfile <&5 ; do
          if [ ! -z $xfile  ] ; then
              if [ ! -z "$bls_opt_outputflstringremap" ] ; then
                  read xfileremap <&6
              fi

              if [ -z $xfileremap ] ; then
                xfileremap="$xfile"
              fi
              if [ "${xfileremap:0:1}" != "/" ] ; then
                xfileremap=${bls_opt_workdir}/${xfileremap}
              fi
              bls_test_shared_dir "$xfileremap"
              if [ "x$bls_is_in_shared_dir" != "xyes" ] ; then
                  xfile_base="`basename ${xfile}`"
                  xfile_transfer="${blah_wn_outputsandbox}${xfile_base}.$uni_ext"
                  bls_fl_add_value outputsand "$xfileremap" "$xfile_transfer" "$xfile"
              else
                  bls_fl_add_value outputmove "$xfileremap" "$xfile"
              fi
          fi
      done
      exec 5<&-
      exec 6<&-
  fi
} 

function bls_add_job_wrapper ()
{
  # Set the required environment variables (escape values with double quotes)
  if [ "x$bls_opt_environment" != "x" ] ; then
          echo "" >> $bls_tmp_file
          echo "# Setting the environment:" >> $bls_tmp_file
  	eval "env_array=($bls_opt_environment)"
          for  env_var in "${env_array[@]}"; do
                   echo export \"$env_var\" >> $bls_tmp_file
          done
  else
          if [ "x$bls_opt_envir" != "x" ] ; then
                  echo "" >> $bls_tmp_file
                  echo "# Setting the environment:" >> $bls_tmp_file
                  echo "`echo ';'$bls_opt_envir | sed -e 's/;[^=]*;/;/g' -e 's/;[^=]*$//g' | sed -e 's/;\([^=]*\)=\([^;]*\)/;export \1=\"\2\"/g' | awk 'BEGIN { RS = ";" } ; { print $0 }'`" >> $bls_tmp_file
          fi
  fi
  
  echo "old_home=\`pwd\`">>$bls_tmp_file
  # Set the temporary home (including cd'ing into it)
  if [ "x$bls_opt_run_dir" != "x" ] ; then
    run_dir="$bls_opt_run_dir"
  else
    run_dir="home_$bls_tmp_name"
  fi
  if [ -n "$blah_wn_temporary_home_dir" ] ; then
    echo "new_home=${blah_wn_temporary_home_dir}/$run_dir">>$bls_tmp_file
  else
    echo "new_home=\${old_home}/$run_dir">>$bls_tmp_file
  fi

  echo "mkdir \$new_home">>$bls_tmp_file
  echo "trap 'cd \$old_home; rm -rf \$new_home; exit 255' 1 2 3 15 24" >> $bls_tmp_file
  echo "trap 'cd \$old_home; rm -rf \$new_home' 0" >> $bls_tmp_file

  echo "# Copy into new home any shared input sandbox file" >> $bls_tmp_file
  bls_fl_subst_and_dump inputcopy "cp \"@@F_LOCAL\" \"\$new_home/@@F_REMOTE\" &> /dev/null" $bls_tmp_file
  echo "# Move into new home any relative input sandbox file" >> $bls_tmp_file
  bls_fl_subst_relative_paths_and_dump inputsand "mv \"@@F_REMOTE\" \"\$new_home/@@F_WORKNAME\" &> /dev/null" $bls_tmp_file

  echo "export HOME=\$new_home">>$bls_tmp_file
  echo "cd \$new_home">>$bls_tmp_file
  
  # Set the path to the user proxy
  if [ "x$bls_need_to_reset_proxy" == "xyes" ] ; then
      echo "# Resetting proxy to local position" >> $bls_tmp_file
      echo "export X509_USER_PROXY=\$new_home/${bls_proxy_remote_file}" >> $bls_tmp_file
  fi
  
  # Add the command (with full path if not staged)
  echo "" >> $bls_tmp_file
  echo "# Command to execute:" >> $bls_tmp_file
  if [ "x$bls_opt_stgcmd" == "xyes" ] 
  then
      bls_opt_the_command="./`basename $bls_opt_the_command`"
      echo "if [ ! -x $bls_opt_the_command ]; then chmod u+x $bls_opt_the_command; fi" >> $bls_tmp_file
      echo "if [ -x \${GLITE_LOCATION:-/opt/glite}/libexec/jobwrapper ]" >> $bls_tmp_file
      echo "then" >> $bls_tmp_file
      echo "\${GLITE_LOCATION:-/opt/glite}/libexec/jobwrapper $bls_opt_the_command $bls_arguments &" >> $bls_tmp_file
      echo "elif [ -x /opt/lcg/libexec/jobwrapper ]" >> $bls_tmp_file
      echo "then" >> $bls_tmp_file
      echo "/opt/lcg/libexec/jobwrapper $bls_opt_the_command $bls_arguments &" >>$bls_tmp_file
      echo "elif [ -x \$BLAH_AUX_JOBWRAPPER ]" >> $bls_tmp_file
      echo "then" >> $bls_tmp_file
      echo "\$BLAH_AUX_JOBWRAPPER $bls_opt_the_command $bls_arguments &" >>$bls_tmp_file
      echo "else" >>$bls_tmp_file
      echo "\$new_home/`basename $bls_opt_the_command` $bls_arguments &" >> $bls_tmp_file
      echo "fi" >>$bls_tmp_file
  else
      echo "$blah_job_wrapper $bls_opt_the_command $bls_arguments &" >> $bls_tmp_file
  fi
  
  echo "job_pid=\$!" >> $bls_tmp_file
  
  if [ "x$bls_opt_proxyrenew" == "xyes" ]
  then
      echo "" >> $bls_tmp_file
      echo "# Start the proxy renewal server" >> $bls_tmp_file
      echo "if [ ! -x \"$remote_BPRserver\" ]; then chmod u+x \"$remote_BPRserver\"; fi" >> $bls_tmp_file
      echo "\"$remote_BPRserver\" \$job_pid $bls_opt_prnpoll $bls_opt_prnlifetime \${$bls_job_id_for_renewal} &" >> $bls_tmp_file
      echo "server_pid=\$!" >> $bls_tmp_file
  fi
  
  echo "" >> $bls_tmp_file
  echo "# Wait for the user job to finish" >> $bls_tmp_file
  echo "wait \$job_pid" >> $bls_tmp_file
  echo "user_retcode=\$?" >> $bls_tmp_file

  if [ "x$blah_debug_save_wn_files" != "x" ]; then
      echo "if [ -d $blah_debug_save_wn_files ]; then" >> $bls_tmp_file
      echo "  blw_save_dir=\"$blah_debug_save_wn_files/\`basename \$new_home\`.debug\"" >> $bls_tmp_file
      echo "  mkdir \$blw_save_dir" >> $bls_tmp_file
      echo "  # Saving files for debug"  >> $bls_tmp_file
      echo "  cp \$X509_USER_PROXY \$blw_save_dir" >> $bls_tmp_file
      [ -z ${bls_unique_stdout_name} ] || echo "  cp $bls_unique_stdout_name \$blw_save_dir" >> $bls_tmp_file
      [ -z ${bls_unique_stderr_name} ] || echo "  cp $bls_unique_stderr_name \$blw_save_dir" >> $bls_tmp_file
      echo "fi" >> $bls_tmp_file
  fi

  if [ "x$bls_opt_proxyrenew" == "xyes" ]
  then
      echo "# Kill the watchdog when done" >> $bls_tmp_file
      echo "sleep 1" >> $bls_tmp_file
      echo "kill \$server_pid 2> /dev/null" >> $bls_tmp_file
  fi
  
  echo ""  >> $bls_tmp_file
  echo "# Move all relative outputsand paths out of temp home" >> $bls_tmp_file
  echo "cd \$new_home" >> $bls_tmp_file
  bls_fl_subst_relative_paths_and_dump outputsand "mv \"@@F_WORKNAME\" \"@@F_REMOTE\" 2> /dev/null" $bls_tmp_file "\\\$old_home" 
  echo "# Move any remapped outputsand file to shared directories" >> $bls_tmp_file
  bls_fl_subst_relative_paths_and_dump outputmove "mv \"@@F_REMOTE\" \"@@F_LOCAL\" 2> /dev/null" $bls_tmp_file
  
  echo ""  >> $bls_tmp_file
  echo "# Remove the staged files, if any" >> $bls_tmp_file
  bls_fl_subst_and_dump inputcopy "rm \"@@F_REMOTE\" 2> /dev/null" $bls_tmp_file
  bls_fl_subst_relative_paths_and_dump inputsand "rm \"@@F_WORKNAME\" 2> /dev/null" $bls_tmp_file

  echo "cd \$old_home" >> $bls_tmp_file
  
  echo "" >> $bls_tmp_file
  
  echo "exit \$user_retcode" >> $bls_tmp_file

  # Exit if it was just a test
  if [ "x$debug" == "xyes" ]
  then
      exit 255
  fi

  if [ "x$bls_opt_workdir" != "x" ]; then
      cd $bls_opt_workdir
  elif [ "x$blah_set_default_workdir_to_home" == "xyes" ]; then
      cd $HOME
  fi

  if [ $? -ne 0 ]; then
      echo "Failed to CD to Initial Working Directory." >&2
      echo Error # for the sake of waiting fgets in blahpd
      rm -f $bls_tmp_file
      exit 1
  fi
}

function bls_set_up_local_and_extra_args ()
{
  if [ -r $bls_local_submit_attributes_file ] ; then
      echo \#\!/bin/sh > $bls_opt_tmp_req_file
      if [ ! -z $bls_opt_req_file ] ; then
          cat $bls_opt_req_file >> $bls_opt_tmp_req_file
      fi
      if [ -n "$bls_opt_mpinodes" ]; then
          echo "blah_opt_mpinodes=$bls_opt_mpinodes" >> $bls_opt_tmp_req_file
      fi
      echo "source $bls_local_submit_attributes_file" >> $bls_opt_tmp_req_file
      chmod +x $bls_opt_tmp_req_file
      $bls_opt_tmp_req_file >> $bls_tmp_file 2> /dev/null
  fi
  if [ -e $bls_opt_tmp_req_file ] ; then
      rm -f $bls_opt_tmp_req_file
  fi
  
  if [ ! -z "$bls_opt_xtra_args" ] ; then
      echo -e $bls_opt_xtra_args >> $bls_tmp_file 2> /dev/null
  fi
}

function bls_wrap_up_submit ()
{

  if [ -d "$blah_debug_save_submit_info" -a -n "$bls_tmp_name" ]; then
    # Store files used for this job in a directory
    bls_info_dir="$blah_debug_save_submit_info/$bls_tmp_name.debug"     
    mkdir "$bls_info_dir"
    if [ $? -eq 0 ]; then
      # Best effort.
      if [ -r "$bls_proxy_local_file" ]; then
        cp "$bls_proxy_local_file" "$bls_info_dir/submit.proxy"
      fi
      if [ -r "$bls_opt_stdout" ]; then
        ln "$bls_opt_stdout" "$bls_info_dir/job.stdout"
        if [ $? -ne 0 ]; then
          # If we cannot hardlink, try a soft link.
          ln -s "$bls_opt_stdout" "$bls_info_dir/job.stdout"
        fi
      fi
      if [ -r "$bls_opt_stderr" ]; then
        ln "$bls_opt_stderr" "$bls_info_dir/job.stderr"
        if [ $? -ne 0 ]; then
          # If we cannot hardlink, try a soft link.
          ln -s "$bls_opt_stderr" "$bls_info_dir/job.stderr"
        fi
      fi
      if [ -r "$bls_tmp_file" ]; then
        cp "$bls_tmp_file" "$bls_info_dir/submit.script"
      fi
    fi
  fi

  bls_fl_clear inputsand
  bls_fl_clear outputsand
  bls_fl_clear inputcopy
  bls_fl_clear outputmove

  # Clean temporary files
  cd $bls_opt_temp_dir
  # DEBUG: cp $bls_tmp_file /tmp
  rm -f $bls_tmp_file
  
  if [ "x$job_registry" == "x" ]; then
    # Create a softlink to proxy file for proxy renewal
    if [ -r "$bls_proxy_local_file" -a -f "$bls_proxy_local_file" ] ; then
        [ -d "$bls_proxy_dir" ] || mkdir $bls_proxy_dir
        ln -s $bls_proxy_local_file $bls_proxy_dir/$jobID.proxy
    fi
  fi
}
