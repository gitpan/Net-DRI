## Domain Registry Interface, EURid Registrar EPP extension notifications
## (introduced in release 5.6 october 2008)
##
## Copyright (c) 2009,2012 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::EURid::Notifications;

use strict;
use warnings;

use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Notifications - EURid EPP Notifications Handling for Net::DRI

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

Copyright (c) 2009,2012 Patrick Mevzek <netdri@dotandco.com>.
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
          notification => [ undef, \&parse ],
         );

 return { 'message' => \%tmp };
}

sub setup
{
 my ($class,$po,$version)=@_;
 $po->ns({ 'poll' => [ 'http://www.eurid.eu/xml/epp/poll-1.0','poll-1.0.xsd' ] });
}

####################################################################################################

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $poll=$mes->get_response('poll','pollData');
 return unless defined $poll;

 my %n;
 my ($action,$returncode,$level);
 foreach my $el (Net::DRI::Util::xml_list_children($poll))
 {
  my ($name,$c)=@$el;
  if ($name=~m/^(context|object|action|code|detail)$/)
  {
   $n{$1}=$c->textContent();
  }
 }

 $rinfo->{session}->{notification}=\%n;
 if ($n{context}=~m/^(?:DOMAIN|TRANSFER)$/)
 {
  $oname=$n{object};
  $rinfo->{domain}->{$oname}->{notification_code}=$n{code};
  $rinfo->{domain}->{$oname}->{action}=$n{action};
  $rinfo->{domain}->{$oname}->{detail}=$n{detail} if exists $n{detail};
  $rinfo->{domain}->{$oname}->{exist}=1;
 }
}

####################################################################################################
1;
