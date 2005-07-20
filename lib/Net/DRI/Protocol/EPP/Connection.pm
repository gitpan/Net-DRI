## Domain Registry Interface, EPP Connection handling
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

package Net::DRI::Protocol::EPP::Connection;

use strict;
use Net::DRI::Protocol::EPP::Message;
use Net::DRI::Data::Raw;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Connection - EPP Connection handling for Net::DRI

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


###############################################################################

sub login
{
 shift if ($_[0] eq __PACKAGE__);
 my ($id,$pass,$cltrid,$dr)=@_;

 my $got=Net::DRI::Protocol::EPP::Message->new();
 $got->parse($dr);
 my $rg=$got->result_greeting();

 my $mes=Net::DRI::Protocol::EPP::Message->new();
 $mes->command(['login']);
 my @d;
 push @d,['clID',$id];
 push @d,['pw',$pass];
 push @d,['options',[['version',$rg->{version}->[0]],['lang','en']]];

 my @s;
 push @s,map { ['objURI',$_] } @{$rg->{svcs}};
 push @s,['svcExtension',[map {['extURI',$_]} @{$rg->{svcext}}]];
 push @d,['svcs',\@s];

 $mes->command_body(\@d);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes->as_string('tcp');
}

sub logout
{
 shift if ($_[0] eq __PACKAGE__);
 my $cltrid=shift(@_);
 my $mes=Net::DRI::Protocol::EPP::Message->new();
 $mes->command(['logout']);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes->as_string('tcp');
}

sub keepalive
{
 shift if ($_[0] eq __PACKAGE__);
 my $cltrid=shift(@_);
 my $mes=Net::DRI::Protocol::EPP::Message->new();
 $mes->command([['poll',{'op'=>'req'}]]); ## It should be ok, since ACK is necessary to really dequeue
 $mes->cltrid($cltrid) if $cltrid;
 return $mes->as_string('tcp');
}

####################################################################################################

sub get_data
{
 shift if ($_[0] eq __PACKAGE__);
 my ($to,$sock)=@_;

 my $c;
 $sock->read($c,4); ## first 4 bytes are the packed length
 my $length=unpack('N',$c)-4;
 my $m;
 $sock->read($m,$length);
 die() unless ($m=~m!</epp>$!);
 return Net::DRI::Data::Raw->new_from_string($m);
}

sub is_greeting_successful
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 return ($dc->as_string()=~m/<greeting>/)? 1 : 0;
}

sub is_login_successful
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 my $code=find_code($dc);
 return (defined($code) && ($code==1000));
}

sub is_server_close
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 my $code=find_code($dc);
 return (defined($code) && ($code=~m/^(?:1500|250[012])$/));
}

sub find_code
{
 my $dc=shift;
 my $a=$dc->as_string();
 return undef unless ($a=~m!</epp>!);
 return 1000  if ($a=~m!<greeting>!);
 $a=~s/[\n\s\t]+//g;
 return undef unless ($a=~m!<response><resultcode=["'](\d+)["']>!);
 return 0+$1; 
}

###################################################################################################################:
1;
