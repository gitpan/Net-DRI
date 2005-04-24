## Domain Registry Interface, Misc. useful functions
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
#########################################################################################

package Net::DRI::Util;

use strict;

use Time::HiRes ();
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d"."%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Util

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


#######################################################################################################

sub all_valid
{
 foreach (@_)
 {
  return 0 unless (defined($_) && $_);
 }
 return 1;
}

#############################################################################################

sub isint
{
 my $in=shift;
 return ($in=~m/^\d+$/)? 1 : 0;
}

sub check_equal
{
 my ($input,$ra,$default)=@_;
 return $default unless defined($input);
 foreach my $a (ref($ra)? @$ra : ($ra))
 {
  return $a if ($a=~m/^${input}$/);
 }
 return ($default)? $default : undef;
}

sub check_isa
{
 my ($what,$isa)=@_;
 Net::DRI::Exception::usererr_invalid_parameters((${what} || 'parameter')." must be a ${isa} object") unless ($what && ref($what) && $what->isa($isa));
 return 1;
}

#################################################################################################

sub microtime
{
 my ($t,$v)=Time::HiRes::gettimeofday();
 return $t.sprintf("%06d",$v);
}

sub create_trid_1
{
 my ($name)=@_;
 my $mt=microtime(); ## length=16
 return uc($name)."-".$$."-".$mt;
}

########################################################################################################

sub is_hostname
{
 my ($name)=@_;
 
 return 0 unless defined($name);

 my @d=split(/\./,$name,-1);
 foreach my $d (@d)
 { 
  return 0 unless (defined($d) && $d);
  return 0 unless (length($d)<=63);
  return 0 if (($d=~m/[^A-Za-z0-9\-]/) || ($d=~m/^-/) || ($d=~m/-$/));
 }
 return 1;
}

sub is_ipv4 
{
 my ($ip,$checkpublic)=@_;

 return 0 unless defined($ip);
 my (@ip)=($ip=~m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
 return 0 unless (@ip==4);
 foreach my $s (@ip)
 {
  return 0 unless (($s >= 0) && ($s <= 255));
 }

 return 1 unless (defined($checkpublic) && $checkpublic);

 ## Check if this IP is public (see RFC3330)
 return 0 if ($ip[0] == 0); ## 0.x.x.x [ RFC 1700 ]
 return 0 if ($ip[0] == 10); ## 10.x.x.x [ RFC 1918 ]
 return 0 if ($ip[0] == 127); ## 127.x.x.x [ RFC 1700 ]
 return 0 if (($ip[0] == 169) && ($ip[1]==254)); ## 169.254.0.0/16 link local
 return 0 if (($ip[0] == 172 ) && ($ip[1]>=16) && ($ip[1]<=31)); ## 172.16.x.x to 172.31.x.x [ RFC 1918 ]
 return 0 if (($ip[0] == 192 ) && ($ip[1]==0) && ($ip[2]==2)); ## 192.0.2.0/24 TEST-NET
 return 0 if (($ip[0] == 192 ) && ($ip[1]==168)); ## 192.168.x.x [ RFC 1918 ]
 return 0 if (($ip[0] >= 224) && ($ip[0] < 240 )); ## 224.0.0.0/4 Class D [ RFC 3171]
 return 0 if ($ip[0] >= 240); ## 240.0.0.0/4 Class E [ RFC 1700 ]
 return 1;
}

## Inspired by Net::IP which unfortunately requires Perl 5.8
sub is_ipv6
{
 my ($ip,$checkpublic)=@_;

 return 0 unless defined($ip);

 my (@ip)=split(/:/,$ip);
 return 0 unless ((@ip > 0) && (@ip < 8));

 return 0 if (($ip=~m/^:[^:]/) || ($ip=~m/[^:]:$/));
 return 0 if ($ip =~ s/:(?=:)//g > 1);
 
 ## We do not allow IPv4 in IPv6
 return 0 if grep { ! /^[a-f\d]{0,4}$/i } @ip;

 return 1 unless (defined($checkpublic) && $checkpublic);

 ## Check if this IP is public
 my ($ip1,$ip2)=split(/::/,$ip);
 $ip1=join("",map { sprintf("%04s",$_) } split(/:/,$ip1));
 $ip2=join("",map { sprintf("%04s",$_) } split(/:/,$ip2));
 my $wip=$ip1.('0' x (32-length($ip1)-length($ip2))).$ip2; ## 32 chars
 my $bip=unpack('B128',pack('H32',$wip)); ## 128-bit array

 ## RFC 3513 §2.4
 return 0 if ($bip=~m/^0{127}/); ## unspecified + loopback
 return 0 if ($bip=~m/^1{7}/); ## multicast + link-local unicast + site-local unicast
 ## everything else is global unicast, 
 ## but see §4 and http://www.iana.org/assignments/ipv6-address-space
 return 0 if ($bip=~m/^000/); ## unassigned + reserved (first 6 lines)
 return 1 if ($bip=~m/^001/); ## global unicast (2000::/3)
 return 0; ## everything else is unassigned
}

############################################################################################

sub compare_durations
{
 my ($dtd1,$dtd2)=@_;

 ## from DateTime::Duration module, internally are stored: months, days, minutes, seconds and nanoseconds
 ## those are the keys of the hash ref given by the deltas method
 my %d1=$dtd1->deltas();
 my %d2=$dtd2->deltas();

 ## Not perfect, but should be enough for us
 return (($d1{months}  <=> $d2{months})  ||
         ($d1{days}    <=> $d2{days})    ||
         ($d1{minutes} <=> $d2{minutes}) ||
         ($d1{seconds} <=> $d2{seconds}) 
        );
}

#############################################################################################
1;
