#!/bin/bash

lockdir=/var/tmp/scalelite_transfer_recordings
pidfile=$lockdir/pid
tmplog=$lockdir/$$.log
spooldir={{ bbb_scalelite_transfer_spool_recordings_spooldir }}
target={{ bbb_scalelite_transfer_spool_recordings_target_host }}:$spooldir

ts() { date '+[%Y-%m-%d %H:%M:%S]'; }
log() {
  # Prefix each printed line with a timestamp.
  # Usage: log "message" OR cat file | log
  if [[ $# -gt 0 ]]; then
    echo "$(ts) $*"
  else
    while IFS= read -r line; do
      echo "$(ts) ${line}"
    done
  fi
}

log "transfer_spool_recordings: start (spooldir=${spooldir}, target=${target})"

if ( mkdir ${lockdir} ) 2> /dev/null; then
   echo $$ > $pidfile
   trap 'rm -rf "$lockdir"; exit $?' INT TERM EXIT

   # transfer files to destination host
   # Note: keep a raw rsync log file for debugging, but also print timestamped lines to stdout.
   rsync -avi --numeric-ids --remove-source-files --delete "$spooldir/" "$target" > "$tmplog" 2>&1
   syncStatus=$?

   # Always print rsync output on error.
   if [[ "$syncStatus" != "0" ]]; then
      log "*** rsync failed (exit=$syncStatus) ***"
      < "$tmplog" log
   else
      # Print output only when there were actual changes.
      if [[ "$(stat --printf="%s" "$tmplog")" -gt "0" ]] && [[ -z "$(grep -F 'total size is 0' "$tmplog" || true)" ]]; then
         log "=== Sync output"
         < "$tmplog" log
      else
         log "No changes"
      fi
   fi

   # clean up after yourself, and release your trap
   rm -rf "$lockdir"
   trap - INT TERM EXIT
   log "transfer_spool_recordings: done"
else
   log "Lock Exists: $lockdir owned by $(cat $pidfile)"
fi
