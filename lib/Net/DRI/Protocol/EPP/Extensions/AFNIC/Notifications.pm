## Domain Registry Interface, AFNIC EPP Notifications
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Notifications - AFNIC (.FR/.RE) EPP Notifications for Net::DRI

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

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           review_zonecheck => [ undef, \&parse_zonecheck ],
         );

 return { 'message' => \%tmp };
}

####################################################################################################

sub parse_zonecheck
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 return unless $mes->node_msg(); ## this is the <msg> node in the EPP header

 my $zc=$mes->node_msg()->getChildrenByTagNameNS($mes->ns('frnic'),'resZC'); ## TODO : for now there is no namespace !!
 return unless $zc->size();
 $zc=$zc->shift();
 return unless ($zc->getAttribute('type') eq 'plain-text'); ## we do not know what to do with other types

 $rinfo->{domain}->{$oname}->{review_zonecheck}=$zc->getFirstChild()->getData(); ## a blob for now
 $rinfo->{domain}->{$oname}->{action}='review_zonecheck';
}

####################################################################################################
1;
