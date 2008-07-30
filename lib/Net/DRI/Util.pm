## Domain Registry Interface, Misc. useful functions
##
## Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

our $VERSION=do { my @r=(q$Revision: 1.17 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Util - Various useful functions for Net::DRI operations

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

Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


####################################################################################################

our %CCA2=map { $_ => 1 } qw/AF AX AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ BM BT BO BA BW BV BR IO BN BG BF BI KH CM CA CV KY CF TD CL CN CX CC CO KM CG CD CK CR CI HR CU CY CZ DK DJ DM DO EC EG SV GQ ER EE ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG GN GW GY HT HM HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MK MG MW MY MV ML MT MH MQ MR MU YT MX FM MD MC MN MS MA MZ MM NA NR NP NL AN NC NZ NI NE NG NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA RE RO RU RW SH KN LC PM VC WS SM ST SA SN CS SC SL SG SK SI SB SO ZA GS ES LK SD SR SJ SZ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV UG UA AE GB US UM UY UZ VU VA VE VN VG VI WF EH YE ZM ZW/;

sub all_valid
{
 foreach (@_)
 {
  return 0 unless (defined($_) && $_);
 }
 return 1;
}

sub hash_merge
{
 my ($rmaster,$rtoadd)=@_;
 while(my ($k,$v)=each(%$rtoadd))
 {
  $rmaster->{$k}={} unless exists($rmaster->{$k});
  while(my ($kk,$vv)=each(%$v))
  {
   $rmaster->{$k}->{$kk}=[] unless exists($rmaster->{$k}->{$kk});
   my @t=@$vv;
   push @{$rmaster->{$k}->{$kk}},\@t;
  }
 }
}

####################################################################################################

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
 return $default if $default;
 return;
}

sub check_isa
{
 my ($what,$isa)=@_;
 Net::DRI::Exception::usererr_invalid_parameters((${what} || 'parameter').' must be a '.$isa.' object') unless ($what && UNIVERSAL::isa($what,$isa));
 return 1;
}

sub isa_contactset
{
 my $cs=shift;
 return (defined($cs) && UNIVERSAL::isa($cs, 'Net::DRI::Data::ContactSet') && !$cs->is_empty())? 1 : 0;
}

sub isa_contact
{
 my ($c,$class)=@_;
 $class='Net::DRI::Data::Contact' unless defined($class);
 return (defined($c) && UNIVERSAL::isa($c,$class))? 1 : 0; ## no way to check if it is empty or not ? Contact->validate() is too strong as it may die, Contact->roid() maybe not ok always
}

sub isa_hosts
{
 my $h=shift;
 return (defined($h) && UNIVERSAL::isa($h, 'Net::DRI::Data::Hosts') && !$h->is_empty())? 1 : 0;
}

sub isa_nsgroup
{
 my $h=shift;
 return (defined($h) && UNIVERSAL::isa($h, 'Net::DRI::Data::Hosts'))? 1 : 0;
}

sub isa_changes
{
 my $c=shift;
 return (defined($c) && UNIVERSAL::isa($c, 'Net::DRI::Data::Changes') && !$c->is_empty())? 1 : 0;
}

sub isa_statuslist
{
 my $s=shift;
 return (defined($s) && UNIVERSAL::isa($s,'Net::DRI::Data::StatusList') && !$s->is_empty())? 1 : 0;
}

sub has_key
{
 my ($rh,$key)=@_;
 return 0 unless (defined($key) && $key);
 return 0 unless (defined($rh) && (ref($rh) eq 'HASH') && exists($rh->{$key}) && defined($rh->{$key}));
 return 1;
}

sub has_contact
{
 my $rh=shift;
 return has_key($rh,'contact') && isa_contactset($rh->{contact});
}

sub has_ns
{
 my $rh=shift;
 return has_key($rh,'ns') && isa_hosts($rh->{ns});
}

sub has_duration
{
 my $rh=shift;
 return has_key($rh,'duration') && check_isa($rh->{'duration'},'DateTime::Duration'); ## check_isa throws an Exception if not
}

sub has_auth
{
 my $rh=shift;
 return (has_key($rh,'auth') && (ref($rh->{'auth'}) eq 'HASH'))? 1 : 0;
}

####################################################################################################

sub microtime
{
 my ($t,$v)=Time::HiRes::gettimeofday();
 return $t.sprintf('%06d',$v);
}

## From EPP, trID=token from 3 to 64 characters
sub create_trid_1
{
 my ($name)=@_;
 my $mt=microtime(); ## length=16
 return uc($name).'-'.$$.'-'.$mt;
}

####################################################################################################

sub is_hostname ## RFC952/1123
{
 my ($name)=@_;
 return 0 unless defined($name);

 my @d=split(/\./,$name,-1);
 foreach my $d (@d)
 {
  return 0 unless (defined($d) && ($d ne ''));
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
 return 0 unless ((@ip > 0) && (@ip <= 8));
 return 0 if (($ip=~m/^:[^:]/) || ($ip=~m/[^:]:$/));
 return 0 if ($ip =~ s/:(?=:)//g > 1);

 ## We do not allow IPv4 in IPv6
 return 0 if grep { ! /^[a-f\d]{0,4}$/i } @ip;

 return 1 unless (defined($checkpublic) && $checkpublic);

 ## Check if this IP is public
 my ($ip1,$ip2)=split(/::/,$ip);
 $ip1=join('',map { sprintf('%04s',$_) } split(/:/,$ip1 || ''));
 $ip2=join('',map { sprintf('%04s',$_) } split(/:/,$ip2 || ''));
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

####################################################################################################

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

####################################################################################################

sub xml_is_normalizedstring
{
 my ($what,$min,$max)=@_;

 return 0 unless defined($what);
 return 0 if ($what=~m/[\r\n\t]/);
 my $l=length($what);
 return 0 if (defined($min) && ($l < $min));
 return 0 if (defined($max) && ($l > $max));
 return 1;
}

sub xml_is_token
{
 my ($what,$min,$max)=@_;

 return 0 unless defined($what);
 return 0 if ($what=~m/[\r\n\t]/);
 return 0 if ($what=~m/^\s/);
 return 0 if ($what=~m/\s$/);
 return 0 if ($what=~m/\s\s/);

 my $l=length($what);
 return 0 if (defined($min) && ($l < $min));
 return 0 if (defined($max) && ($l > $max));
 return 1;
}

sub xml_is_ncname ## xml:id is of this type
{
 my ($what)=@_;
 return 0 unless defined($what) && $what;
 return ($what=~m/^\p{ID_Start}\p{ID_Continue}*$/)
}

sub verify_ushort { my $in=shift; return (defined($in) && ($in=~m/^\d+$/) && ($in < 65536))? 1 : 0; }
sub verify_ubyte  { my $in=shift; return (defined($in) && ($in=~m/^\d+$/) && ($in < 256))? 1 : 0; }
sub verify_hex    { my $in=shift; return (defined($in) && ($in=~m/^[0-9A-F]+$/i))? 1 : 0; }
sub verify_int
{
 my ($in,$min,$max)=@_;
 return 0 unless defined($in) && ($in=~m/^-?\d+$/);
 return 0 if ($in < (defined($min)? $min : -2147483648));
 return 0 if ($in > (defined($max)? $max : 2147483647));
 return 1;
}

sub verify_base64
{
 my ($in,$min,$max)=@_;
 my $b04='[AQgw]';
 my $b16='[AEIMQUYcgkosw048]';
 my $b64='[A-Za-z0-9+/]';
 return 0 unless ($in=~m/^(?:(?:$b64 ?$b64 ?$b64 ?$b64 ?)*(?:(?:$b64 ?$b64 ?$b64 ?$b64)|(?:$b64 ?$b64 ?$b16 ?=)|(?:$b64 ?$b04 ?= ?=)))?$/);
 return 0 if (defined($min) && (length($in) < $min));
 return 0 if (defined($max) && (length($in) > $max));
 return 1;
}

## Same in XML and in RFC3066
sub xml_is_language
{
 my $in=shift;
 return 0 unless defined($in);
 return 1 if ($in=~m/^[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*$/);
 return 0;
}

sub xml_is_boolean
{
 my $in=shift;
 return 0 unless defined($in);
 return 1 if ($in=~m/^(?:1|0|true|false)$/);
 return 0;
}

sub xml_parse_boolean
{
 my $in=shift;
 return {'true'=>1,1=>1,0=>0,'false'=>0}->{$in};
}

sub xml_escape
{
 my ($in)=@_;
 $in=~s/&/&amp;/g;
 $in=~s/</&lt;/g;
 $in=~s/>/&gt;/g;
 return $in;
}

sub remcam
{
 my $in=shift;
 $in=~s/ID/_id/g;
 $in=~s/([A-Z])/_$1/g;
 return lc($in);
}

####################################################################################################
1;
