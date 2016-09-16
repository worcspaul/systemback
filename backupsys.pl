#!/usr/bin/perl

use Getopt::Std;
$MAJORREV=1;
$subrev=0;
$fixrev=0;
#	backupsys.pl	-	Script to backup filesystems to remote server using dump
$SSH = "/usr/bin/ssh";
$BACKUP_HOME="/backups";
$LOCALCFG=$BACKUP_HOME."/config.pl";
$LOGPATH="/var/log/backups";

$BACKUPHOST="hq-app-backup01.prod.impello.co.uk";
$backup_command = "/sbin/dump";
$restore_command = "/sbin/restore";

## require "$LOCALCFG";

$Masthead = sprintf("[backupsys v%d.%d.%d (c) 2016 First Utility Ltd.]",$MAJORREV,$subrev,$fixrev);

getopts('ihd');

#====================================================================
# log_message - Log the passed message to syslog
#====================================================================

sub log_message {
   $MSG = shift(@_);
   $command = sprintf("logger -p local7.info -t backup %s",$MSG);
   system($command);
}

#====================================================================
# write_log - Write a ling to log file indicating outcome of backup
#             and timing information.
#====================================================================

sub write_log {
   $Status = shift(@_);
#   printf("ELOG: %s %s %s %s %s\n",$Status,$bkType,$Start_Time,$Now,$Elapsed_Time);
   open(ELOG,">>$LogFile");
   printf(ELOG "%s %s %s %s %s\n",$Status,$bkType,$Start_Time,$Now,$Elapsed_Time);
   close(ELOG);
}


#====================================================================
# execute_command - Execute a UNIX command and return the correct 
#                   return code
#====================================================================

sub execute_command {
   $comm = shift(@_);
   system($comm);
#if ($? == -1) {
#    print "failed to execute: $!\n";
#}
#elsif ($? & 127) {
#    printf "child died with signal %d, %s coredump\n",
#    ($? & 127),  ($? & 128) ? 'with' : 'without';
#}
#else {
#    printf "child exited with value %d\n", $? >> 8;
#}
#   $rc = $RC/256;
$rc=$?;
   $rc;
}
#====================================================================
# fmt_time - take a time in seconds and display it as HH:MM:SS
#====================================================================
#
sub fmt_time {
   $sec = shift(@_);
   $dsec = 86400;
   $hsec = 3600;
   
   $days=int($sec/$dsec);
   $hours=($sec/($hsec))%24;
   $mins  = ($sec/60)%60;
   $secs  = $sec%60;
   if ( $days > 0) {
      $fmt_tim=sprintf("%d %d:%02d:%02d\n",$days,$hours,$mins,$secs);
   } else {
      $fmt_tim=sprintf("%d:%02d:%02d\n",$hours,$mins,$secs);
      $fmt_tim;
   }
}

#====================================================================
# display_help - Show what options are available 
#====================================================================

sub display_help {
   print "SYNOPSIS
	backupsys [-d] [-i] [-h]

DESCRIPTION
	The backupsys script dumps the contents of non-database related filesystems to disk 
        files then initiates a backup to tape.  This method enables the lastest backup to 
        be retained on disk and	also facilitates faster recovery from tape as fewer files 
        have to be restored.

OPTIONS
	The following options are supported:

	-i	Perform a cumulative incremental (Differential) backup.

        -d      debug - print extra information
        
	-h	You're looking at it!\n\n";

}


#====================================================================
# mail_errors - Set up email header and message to notify of failure
#====================================================================

sub mail_errors {
   open(HDR,">$HEADERFILE");
   printf(HDR "Subject: [BACKUP] backup failed on %s\n",$Sysname);
   printf(HDR "Importance: high\n");
   printf(HDR "X-Priority: 1\n");
   close(HDR);

   $TEXT = shift(@_);
   open(MSG,">$MSGFILE");
   printf(MSG "%s\n%s\n",$Masthead,$TEXT);
   close(MSG);
##   &send_mail("stats");
}
#====================================================================
# mail_start - Set up email header and message to notify of start
#====================================================================

sub mail_start {
   open(HDR,">$HEADERFILE");
   printf(HDR "Subject: [BACKUP] backup of %s to disk files started at %s on %s\n",$enviro,$Now,$Sysname);
   close(HDR);
   open(MSG,">$MSGFILE");
   printf(MSG "%s\n\nBackup of %s to file started at %s\n",$Masthead,$Sysname,$Now);
   close(MSG);

   open(STAT,">$STATSFILE");
   printf(STAT "<div align='left'><table border='1' id='%s'>\n",$jobset);
#   printf(STAT "<tr><td colspan='4'><font size='2' face='Arial'>Job status summary for jobset <b>%s</b></font></td></tr>",$jobset);
   printf(STAT "<tr><td><font size='2' face='Arial'><b>Filesystem</b></font></td><td><font size='2' face='Arial'><b>Size</b></font></td><td><font size='2' face='Arial'><b>Backup<br>Type</b></font></td><td><font size='2' face='Arial'><b>Return<br>code</b></font></td><td><font size='2' face='Arial'><b>Time<br>Taken</b></font></td></tr>");
   close(STAT);

##   &send_mail;
}

#====================================================================
# mail_end - Set up email header and message to notify of end
#====================================================================

sub mail_end {
   open(HDR,">$HEADERFILE");
   printf(HDR "Subject: [BACKUP] backup of %s to disk files finished at %s on %s\n",$enviro, $Now,$Sysname);
   printf(HDR "MIME-Version: 1.0\n");
   printf(HDR "Content-Type: text/html\n");
   printf(HDR "<html><body>\n");
   close(HDR);
   open(STAT,">>$STATSFILE");
   printf(STAT "</table></div>\n");
   printf(STAT "<p></p>\n");
   close(STAT);

   open(MSG,">$MSGFILE");
   printf(MSG "</body></html>\n");
   close(MSG);
##   &send_mail("stats");
}
#====================================================================
# write_stat - write details of success/failure of backup
#====================================================================
sub write_stat {
   $STATF = shift(@_);
   $FS = shift(@_);
   $TYPE = shift(@_);
   $CODE = shift(@_);
   $ETIME = shift(@_);
   $elapsed = &fmt_time($ETIME);
   $Colour = $Green if ($CODE == 0);
   $Colour = $Red if ($CODE > 0);
   $Colour = $Yellow if ($CODE < 0);
   $DF_FS=`df -hP $FS |grep $FS`;
   ($dev,$sz,$used,$avail,$pct_used,$mp) = split(' ',$DF_FS);
   open(STAT,">>$STATF");
   printf(STAT "<tr><td bgcolor='%s'><font size='2' face='Arial'>%s</font></td>",$Colour,$FS);
   printf(STAT "<td><font size=2>%s</font></td>",$used);
   printf(STAT "<td><font size=2>%s</font></td>",$TYPE);
   printf(STAT "<td width='40' align='right'>%d</td><td align='right'>%s</td></tr>\n",$CODE,$elapsed);
   close(STAT);
}

#====================================================================
# send_mail - Send mail to recipients
#====================================================================

##sub send_mail {
##if (defined @_) {
##$base_cmd = sprintf("cat %s %s %s",$HEADERFILE,$STATSFILE,$MSGFILE);
##} else {
##$base_cmd = sprintf("cat %s %s",$HEADERFILE,$MSGFILE);
##}
## foreach $Recipient (@Test) {
###   foreach $Recipient (@Mail_Recipients) {
##      $mailcmd=sprintf("%s | %s %s\@bcu.ac.uk",$base_cmd,$Email_Command,$Recipient);
##      system($mailcmd);
##   }
##}


#====================================================================
# do_backup - Loop through each filesystem and dump to file using
#             dump command specified in config.pl
#====================================================================
sub do_backup {
   open(IN,$FS_INIFILE) || die "Unable to open input file!";
   while ($rec = <IN>) {
      chop($rec);
      ($mountpoint,$dumpfile) = split(":",$rec);

#Check to see if filesystem is mounted before attempting to dump it (not really necessary with dump/ufsdump)
##         $mounted=`mount |grep '$mountpoint '`;
##         chop($mounted);
$mounted = 0;
      open (MTAB,$mtab) || die "Unable to open $mtab to check mounted filesystems";
      while(<MTAB>) {
         if($_ =~ /\S+ (\S+) .*/) {
            $mounted = 1 if ($1 eq $mountpoint);
         }
      }   
      close(MTAB);

      if($mounted == 1) {
         ($instance,$dump_sfx) = split(/\./,$dumpfile);
         printf("dumpfile: %s Instance: %s\n",$dumpfile,$instance);

         $target_dir=sprintf("/backups/%s/%s",$Sysname,$bkType);

         $bkcommand=sprintf("%s %duf - %s | %s backup\@%s \"dd of=%s/%s\"",$backup_command,$BACKUPLEVEL,$mountpoint,$SSH,$BACKUPHOST,$target_dir,$dumpfile);
         $restore_cmd=sprintf("%s rf %s/%s",$restore_command,$target_dir,$dumpfile);
      }
      printf("%s\n",$bkcommand);

      $message=sprintf("BACKUP_I_203 %s backup of %s started.",$bkType,$mountpoint);
      &log_message($message);
      $start_time=time();
##      $rc=&execute_command($bkcommand);
      $finish_time = time();
      $elapsed_time = $finish_time - $start_time;
      $Elapsed_Time=&fmt_time($elapsed_time);
      &write_stat($STATSFILE,$mountpoint,$bkType,$rc,$elapsed_time);

      if ( $rc != 0 ){
         $Now=`date "+%d-%b-%Y %T"`;
         chop($Now);
         $message=sprintf("BACKUP_F_205 %s Backup of %s failed with code %d",$bkType,$mountpoint,$rc);
         &log_message($message);
         $errmsg = sprintf("Dump to file of %s failed at %s.  Elapsed time: %s",$mountpoint,$Now,$Elapsed_Time);
         &mail_errors($errmsg);
         &write_log("F");
      } else {
#ufsdump command completed successfully.  Send message to syslog
            $message=sprintf("BACKUP_I_204 %s backup of %s complete",$bkType,$mountpoint);
            &log_message($message);
#           &update_index;
#        $File_No++;
      }
      printf(OUT "%s/%s\n",$rtarget_dir,$dumpfile);
#Now write a line to the "restorer" script
##         if ($dumpfile !~ /root/) {
##            printf(OUT1 "cd %s\n",$mountpoint);
##            printf(OUT1 "pwd\n");
##            printf(OUT1 "date\n");
##            printf(OUT1 "%s\n",$restore_cmd);
##            printf(OUT1 "date\n");
##         }
   }
   close(IN);
   close(OUT);
##   close(OUT1);
}

#########################################################################################

#====================================================================
#
# MAIN PROGRAM
#
#====================================================================

$Red = "#CC0000";
$Green = "#00BB00";
$Yellow ="#EEBB00";
$White = "#FFFFFF";
$mtab = "/etc/mtab";

$Sysname = `hostname`;
print $Sysname;
chop($Sysname);
$SysType = `uname -s`;
chop($SysType);
if ($SysType eq "SunOS") {
   $mtab = "/etc/mnttab";
}
# If hostname has dots in it, it's a FQDN, so extract the host portion
#if ($Sysname =~ /(\w+)\./ )  {
#   $Sysname=$1;
#}

$bkType="Full";
$enviro="SYSTEM";
$HEADERFILE=sprintf("/tmp/%s_backup_mail_header",$enviro);
$STATSFILE=sprintf("/tmp/%s_backup_mail_stats",$enviro);
$MSGFILE=sprintf("/tmp/%s_backup_mail_msg",$enviro);

$FS_INIFILE=$BACKUP_HOME."/fs.ini";

# If the user has specified -h on command line, output usage and exit

if (defined $opt_h) {
 &display_help;
 exit 0;
}

# If user has requested an Incremental backup, set type to "Inc" and level to 1
if (defined $opt_i) {
   $bkType="Inc";
   $BACKUPLEVEL=1;
}
print "Backup Type:     $bkType\n";

# Set up a couple of log file names based on date/time   
$Now=`date "+%Y%m%d.%H%M%S"`;
chop($Now);
$DUMPLOG=sprintf("%s/%s_%s_dump_log.%s",$LOGPATH,$Sysname,$bkType,$Now);

# If a permanent backup is required, set the policy to YearEnd and the schedule
# to the host class (normally used to determine the _policy_ Also, set the backup
# to be a Full (level 0) backup as there's little point in taking a permanent 
# Incremental

if (defined $opt_p) {
   $policy="YearEnd";
   $schedule=$host_class;
   $bkType="Full";
   $BACKUPLEVEL=0;
}

$target_dir=sprintf("/backups/%s/%s",$Sysname,$bkType);
$files_to_backup=sprintf("%s/files_to_backup.%s",$target_dir,$enviro);
## $restorer_script=sprintf("%s/restorer",$target_dir);

# Output some stuff if -d option used

$DOW=`date "+%a"`;
chop($DOW);
$Now=`date "+%d-%b-%Y %T"`;
chop($Now);
system("echo \"Filesystem dumps started `date`\" >".$DUMPLOG);
$Start_Time=$Now;

if(defined $opt_d) {
   print "Host:            $Sysname\n";
   print "Backup Type:     $bkType\n";
   print "Backup Level:    $BACKUPLEVEL\n";
   print "Day of Week:     $DOW\n";
   print "backup_command:  $backup_command\n";
   print "restore_command: $restore_command\n";
   print "Logging to:      $DUMPLOG\n";
   print "Target Dir:      $target_dir\n";
   print "Files to backup: $files_to_backup\n";
   print "ini file:        $FS_INIFILE\n";
   print "Environment:     $enviro\n";
}


&mail_start;

$Backups_started = time();

## open(OUT,">$files_to_backup");
## if ($host_class eq "BackupServer") {
##    if (defined $opt_e ) {
##       printf(OUT "%s/data/%s/restorer\n",$BACKUP_HOME,$lc_enviro);
##    } else {
##       printf(OUT "%s/filesystems/%s/restorer\n",$BACKUP_HOME,$Sysname);
##    }
## } else {
##    printf(OUT "%s/restorer\n",$rtarget_dir);
## }

$bash_location=`which bash`;
## open(OUT1,">$restorer_script") || die "Unable to open restorer script for writing!";
## printf(OUT1 "#!%s",$bash_location);

&do_backup;

$Backups_finished = time();
$Backups_Elapsed_time = $Backups_finished - $Backups_started;
$Now=`date "+%d-%b-%Y %T"`;
chop($Now);
$message = sprintf("BACKUP_I_206 %s backup of %s finished %s",$bkType,$Sysname,$Now);

&log_message($message);

$Elapsed_Time=&fmt_time($Backups_Elapsed_time);

&mail_end;
&write_log("S");

system("echo \"Filesystem dumps finished `date`\" >>".$DUMPLOG);

##if (defined $opt_N) {
##   &initiate_netbackup;
##}

