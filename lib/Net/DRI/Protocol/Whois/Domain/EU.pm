## Domain Registry Interface, Whois parse for .EU (RFC3912)
##
## Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::EU;

use strict;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Hosts;
use Net::DRI::Protocol::EPP::Core::Status;

use DateTime::Format::Strptime;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::EU - Whois .EU parse (RFC3912) for Net::DRI

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

Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'domain' => { info   => [ \&info, \&info_parse ] } };
}

sub info
{
 my ($po,$domain,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/DAS',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 $mes->command('domain '.lc($domain));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 my $rd=$mes->response_raw();
 my ($domain,$exist)=parse_domain($rr,$rd,$rinfo);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 parse_registrars($domain,$rr,$rinfo);
 parse_dates($domain,$rr,$rinfo);
 parse_status($domain,$rr,$rinfo);
 parse_ns($domain,$rr,$rd,$rinfo);
}

sub parse_domain
{
 my ($rr,$rd,$rinfo)=@_;
 my ($dom,$e);
 $dom=lc($rr->{'Domain'}->[0]).'.eu';
 $e=($rr->{'Status'}->[0] eq 'FREE')? 0 : 1;
 return (lc($dom),$e);
}

sub parse_registrars
{
 my ($domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Name'}->[0];
 $rinfo->{domain}->{$domain}->{clWebsite}=$rr->{'Website'}->[0];
}

sub parse_dates
{
 my ($domain,$rr,$rinfo)=@_;
 my $strp=DateTime::Format::Strptime->new(pattern => '%a %b%n%d %Y', locale => 'en_US', time_zone => 'Europe/Brussels');
 $rinfo->{domain}->{$domain}->{crDate}=$strp->parse_datetime($rr->{'Registered'}->[0]);
}

sub parse_status
{
 my ($domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(['ok']);
}

sub parse_ns
{
 my ($domain,$rr,$rd,$rinfo)=@_;
 my @ns;
 foreach my $l (@$rd)
 {
  next unless (($l=~m/^Nameservers:/)..($l=~m/^\s*$/));
  push @ns,$1 if ($l=~m/^\s*(\S+)/);
 }
 $rinfo->{domain}->{$domain}->{ns}=Net::DRI::Data::Hosts->new_set(@ns) if @ns;
}

####################################################################################################
1;
