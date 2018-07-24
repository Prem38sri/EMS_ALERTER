#!/usr/bin/perl



$inputfile=$ARGV[0];
$subject=$ARGV[1];
open(INPUT,"<$inputfile") or die $!;
open(HTML,">/{INSTALL_HOME}/EMS_ALERTER/tmp/webpage.html") or die $!;
open(HTML1,"</{INSTALL_HOME}/EMS_ALERTER/webpage-part1.html") or die $!;
open(HTML2,"</{INSTALL_HOME}/EMS_ALERTER/webpage-part2.html") or die $!;
open(REPORT,">/{INSTALL_HOME}/EMS_ALERTER/tmp/report.html") or die $!;

foreach(<INPUT>){
	chomp($_);
	my @ips = split /##/, $_;
	$domain = $ips[0];
	$ems_name = $ips[1];
        $ems_url = $ips[2];
	$ems_user = $ips[3];
	$ems_pwd = $ips[4];
	$error;
	$domain_status;
	$domain_prev;
	$domain_prev_status;
	our $notify;
	#$notify=0;
	getstatus($ems_name,$ems_url,$ems_user,$ems_pwd,$error);
	$errorcount=0;
	#print "$errorcount";
}
writehtml();
print $notify;
if ($notify == 1){
sendemail();
}
sub getstatus {
#       print "$ems_name,$ems_url,$ems_user,$ems_pwd,$error\n";

	@command =`timeout 10 /{EMS_BIN}/tibemsadmin -server $ems_url -user $ems_user -password '$ems_pwd' -script /{INSTALL_HOME}/EMS_ALERTER/cmd.txt`;
	for(@command){
			if($_ =~ m/State:/){
				@ems_statusarr = split /:/, $_;
				$ems_status=$ems_statusarr[1];
				$ems_status =~ s/\s+//g;
				chomp($ems_status);
			}elsif($_ =~ m/Server:/ && !(m/Standby/)){
				@ems_serverarr = split /:/, $_; 
				$ems_server = $ems_serverarr[1];
				$ems_server =~ s/^\s+//g;
				$ems_server =~ s/\(.*//g;
				chomp($ems_server);
			}elsif($_ =~ m/Message Memory Usage:/){
				@ems_memoryarr = split /:/, $_;
				$ems_memory = $ems_memoryarr[1];
				$ems_memory =~ s/^\s+//g;
				chomp($ems_memory);

			}elsif($_ =~ m/Asynchronous Storage:/){
				@ems_asyncstoragearr = split /:/, $_;
				$ems_asyncstorage = $ems_asyncstoragearr[1];
				$ems_asyncstorage =~ s/^\s+//g;
				chomp($ems_asyncstorage);
			}elsif($_ =~ m/Uptime:/){
				@ems_uptimearr = split /:/, $_;
				$ems_uptime = $ems_uptimearr[1];
				$ems_uptime =~ s/^\s+//g;
				chomp($ems_uptime);
			}elsif($_ =~ m/Pending Message Size:/){
				@ems_pendingmessagearr = split /:/, $_;
				$ems_pendingmessage = $ems_pendingmessagearr[1];
				$ems_pendingmessage =~ s/^\s+//g;
				chomp($ems_pendingmessage);
			}elsif($_ =~ m/Failed/){
				$ems_status = "Failed";
				$ems_server = "Failed";
				$ems_memory = "Failed";
				$ems_asyncstorage = "Failed";
				$ems_uptime = "Failed";
				$ems_pendingmessage = "Failed";
				$error = $_;		
				$errorcount=1;				
			}
		}
	
	#THIS SECTION IS ADDED on 22nd January 2018 to capture dual active state for EMS instances of same domain
	$domain_status=$ems_status;
	if ($domain eq $domain_prev){
		if ($domain_status eq $domain_prev_status){
			$error="Both instance of domain $domain is in same state";
			$errorcount=1;	
		}
	}
	$domain_prev=$domain;
	$domain_prev_status=$domain_status;
	if ($errorcount == 1){
		$notify=1;
	}	
	getreport($ems_name,$ems_url,$ems_status,$ems_server,$ems_memory,$ems_asyncstorage,$ems_uptime,$ems_pendingmessage,$error);
	$error="";
}

sub getreport {
		$trrcolor ='<tr bgcolor="#FF0000">';
		$trr ="<tr>";
		$tdd ="<td>";
		$trrc ="</tr>";
		$tddc ="</td>";
	
	#	printf "|%-45s |%-20s |%-25s |%-25s |%-10s |%-30s |%-10s|\n",$ems_url,$ems_server,$ems_status,$ems_memory,$ems_asyncstorage,$ems_uptime,$ems_pendingmessage;
		$errorcount == 1 ? print HTML "$trrcolor\n" :  print HTML "$trr\n" ;
		#print "Error is $errorcount\n";
		#if($errorcount=1){
		 #	print HTML "$trrcolor\n";
		#	}else{ 
		#	print HTML "$trr\n";
		#	}
		@alldata = @_;
		foreach(@alldata){
			print HTML "$tdd$_$tddc\n";
		}
		print HTML "$trrc\n";
}

sub writehtml {
		close(HTML);
		open(HTML3,"</{INSTALL_HOME}/EMS_ALERTER/tmp/webpage.html");
		@html1 = <HTML1>;
		@html = <HTML3>;
		@html2 = <HTML2>;	
		print REPORT @html1;
		print REPORT @html;
		print REPORT @html2;
}

sub sendemail {
		 `/{INSTALL_HOME}/EMS_ALERTER/SendMail.sh "$subject"`;
#		`echo "Subject: $subject" | cat - tmp/report.html| /usr/lib/sendmail -f SUPPORT_TEAM -t email@your.com`
}
