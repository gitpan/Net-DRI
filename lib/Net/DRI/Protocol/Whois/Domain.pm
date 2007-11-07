## Domain Registry Interface, Whois Domain commands (RFC3912)
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

package Net::DRI::Protocol::Whois::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain - Whois Domain commands (RFC3912) for Net::DRI

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
 my %tmp=(
           info   => [ \&info, \&info_parse ],
         );

 return { 'domain' => \%tmp };
}

sub info
{
 my ($po,$domain,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/whois',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 $mes->command(build_command($domain,$rd));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 $rinfo->{_internal}->{must_reconnect}=1;

 my ($domain,$exist)=$po->parse_domain($rr,$rinfo);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 $po->parse_registrars($domain,$rr,$rinfo);
 $po->parse_dates($domain,$rr,$rinfo);
 $po->parse_status($domain,$rr,$rinfo);
 $po->parse_contacts($domain,$rr,$rinfo);
 $po->parse_ns($domain,$rr,$rinfo);
}

## Must be defined in subclasses
sub build_command    { Net::DRI::Exception::err_method_not_implemented(); }
sub parse_domain     { Net::DRI::Exception::err_method_not_implemented(); } ## name, roid
sub parse_registrars { Net::DRI::Exception::err_method_not_implemented(); } ## clID,crID,upID
sub parse_dates      { Net::DRI::Exception::err_method_not_implemented(); } ## crDate,upDate,trDate,exDate
sub parse_status     { Net::DRI::Exception::err_method_not_implemented(); }
sub parse_contacts   { Net::DRI::Exception::err_method_not_implemented(); }
sub parse_ns         { Net::DRI::Exception::err_method_not_implemented(); }

####################################################################################################
1;
