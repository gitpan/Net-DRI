## Domain Registry Interface, IRIS LWZ Connection handling
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
####################################################################################################

package Net::DRI::Protocol::IRIS::LWZ;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

use Net::DNS ();
##use IO::Uncompress::RawInflate (); ## TODO
use Encode ();

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::IRIS::LWZ - IRIS LWZ connection handling (RFC4993) for Net::DRI

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

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub read_data # §3.1.2
{
 my ($class,$to,$sock)=@_;

 my $data;
 $sock->recv($data,4000) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Unable to read registry reply: '.$!,'en'));
 my $hdr=substr($data,0,1);

 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Unable to read 1 byte header','en')) unless $hdr;
 # §3.1.3
 ##my @bits=split(//,unpack('B8',$hdr));
 $hdr=unpack('C',$hdr);
 my $ver=($hdr & (128+64)) >> 6;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Version unknown in header: '.$ver,'en')) unless $ver==0;
 my $rr=($hdr & 32) >> 5;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','RR Flag is not response in header: '.$rr,'en')) unless $rr==1;
 my $deflate=($hdr & 16) >> 4; ## if 1, the payload is compressed with the deflate algorithm
 my $type=($hdr & 3); ## §3.1.4
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unexpected response type in header: '.$type,'en')) unless $type==0; ## TODO : handle size info, version, etc.

 my $tid=substr($data,1,2);
 $tid=unpack('n',$tid);

 my $load=substr($data,3);
 if ($deflate)
 {
  die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unexpected deflated reply','en'));
##  my $data2;
##  IO::Uncompress::RawInflate::rawinflate(\$data,\$data2) or die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Unable to uncompress payload: '.$IO::Uncompress::RawInflate::RawInflateError,'en'));
##  $data=$data2;
 }

 my $m=Encode::decode('utf8',$load);
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',$m? 'Got unexpected reply message: '.$m : '<empty message from server>','en')) unless ($m=~m!</(?:\S+:)?response>\s*$!s); ## we do not handle other things than plain responses (see Message)
 return Net::DRI::Data::Raw->new_from_string($m);
}

sub write_message
{
 my ($self,$to,$msg)=@_;

 # §3.1.1 + §3.1.3
 my $hdr='00001000'; ## V=0 RR=Request PD=no DS=yes Reserved PT=xml
 $hdr='00000000'; ## DS=no for now
 my $m=Encode::encode('utf8',$msg->as_string());
 my ($tid)=($msg->tid()=~m/(\d{6})$/); ## 16 digits, we need to convert to a 16-bit value, we take the microsecond part modulo 65535 (since 0xFFFF is reserved)
 $tid%=65535;
 my $auth=$msg->authority();
 return pack('B8',$hdr).pack('n',$tid).pack('n',4000).pack('C',length($auth)).$auth.$m;
}

sub find_remote_server
{
 my ($class,$to,$rd)=@_;
 my ($authority,$service)=@$rd;

 my $res=Net::DNS::Resolver->new();
 my $query=$res->query($authority,'NAPTR');
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to perform NAPTR DNS query for '.$authority.': '.$res->errorstring()) unless $query;

 my @r=sort { $a->order() <=> $b->order() || $a->preference() <=> $b->preference() } grep { $_->type() eq 'NAPTR' } $query->answer(); ## RFC3958 §2.2.1
 @r=grep { $_->service() eq $service } @r; ## RFC3958 §2.2.2
 @r=grep { $_->flags() eq 's' } @r; ## RFC3958 §2.2.3
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to retrieve NAPTR records with service='.$service.' and flags=s for authority='.$authority) unless @r;

 my $srv=$r[0]->replacement();
 $query=$res->query($srv,'SRV');
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to perform SRV DNS query for '.$srv.': '.$res->errorstring()) unless $query;

 @r=$query->answer();
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to retrieve SRV records for '.$srv) unless @r;

 ## TODO: provide load balancing/fail over when not using only one SRV record / This would probably need changes in Transport or Transport::Socket
 @r=Net::DRI::Util::dns_srv_order(@r) if @r > 1;
 Net::DRI::Exception->die(1,'transport/socket',8,'No remote endpoint given, and unable to find valid SRV record for '.$srv) if ($r[0]->target() eq '.');
 return ($r[0]->target(),$r[0]->port());
}

####################################################################################################
1;
