#!/usr/bin/perl
#
#====================================================================
# collect_info	 - Collect useful information
#====================================================================
@IPINFO;
$INFOFILE="/INFOFILE";
$ipcount=0;
$hostname=`hostname`;
$memswap= `free -m`;
$hostid=`hostname`;
$kernel=`uname -r`;
$blkinfo=`lsblk`;
$filesystems= `df -hP`;
$pv=`pvdisplay`;
chop($pv);
printf("Length: %d\n",length($pv));
if (length($pv) > 0) {
   $LVM=1;
}

if (-e "/etc/redhat-release") {
   $OS = `cat /etc/redhat-release`;
} else {
   $OS = `cat /etc/issue`;
}
#     inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
#     inet 10.180.21.44/8 brd 10.255.255.255 scope global eno1
   
open(OUT,">$INFOFILE");
open(IPINFO,"ip addr |grep \"inet \"|");
while ($rec = <IPINFO>) {
   chop($rec);
   if (($rec =~ /inet (\S+) brd (\S+) scope global dynamic (\S+)$/) || ($rec =~ /inet (\S+) brd (\S+) scope global (\S+)$/) ) {
      $ipaddr=$1;
      $broadcast = $2;
      $interface = $3;
      $IPREC=sprintf("%s:%s:%s",$ipaddr, $broadcast, $interface);
      push(@IPINFO,$IPREC);
      $ipcount++;
   }
}
printf(OUT "#############################\n");
printf(OUT "######## SYSTEM INFO ########\n");
printf(OUT "#############################\n\n");
printf(OUT "Hostname:     %s",$hostname);
printf(OUT "O/S:          %s",$OS);
printf(OUT "Kernel:       %s",$kernel);
printf(OUT "Memory:\n%s\n",$memswap);
if ($ipcount > 0) {
   printf(OUT "\n###########################\n");
   printf(OUT "NETWORK");
   printf(OUT "\n###########################\n");
   printf(OUT "\nInterface	IP Address	Broadcast\n");
   foreach $irec (@IPINFO) {
      ($inet,$brd,$int) = split(':',$irec);
      printf(OUT "$int		$inet	$brd\n");
   }
}
printf(OUT "\n###########################\n");
printf(OUT "BLOCK DEVICES");
printf(OUT "\n###########################\n");
printf(OUT "%s",$blkinfo);
printf(OUT "\n###########################\n");
printf(OUT "FILESYSTEMS");
printf(OUT "\n###########################\n");
printf(OUT "%s",$filesystems);
if ($LVM == 1) {
   printf(OUT "\n###########################\n");
   printf(OUT "LOGICAL VOLUME MANAGEMENT");
   printf(OUT "\n###########################\n");
   printf(OUT "\nPHYSICAL VOLUMES\n");
   open(PVS,"pvs|");
   while ($pvrec = <PVS>) {
      printf(OUT "%s",$pvrec);
   }
   close(PVS);
   printf(OUT "\nVOLUME GROUPS\n");
   open(VGS,"vgs|");
   while ($vgrec = <VGS>) {
      printf(OUT "%s",$vgrec);
   }
   close(VGS);
   printf(OUT "\nLOGICAL VOLUMES\n");
   open(LVS,"lvs|");
   while ($lvrec = <LVS>) {
      printf(OUT "%s",$lvrec);
   }
   close(LVS);
}
