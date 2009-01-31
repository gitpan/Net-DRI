## Domain Registry Interface, ``WorldSite.WS'' Registry Driver for .WS
##
## Copyright (c) 2005,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::WS;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::WS - Website.WS .WS Registry driver for Net::DRI

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

Copyright (c) 2005,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub periods      { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name         { return 'WS'; }
sub tlds         { return ('ws'); }
sub object_types { return ('domain','ns'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'RRP') && ($tn eq 'socket_inet'));
 return 1 if (($pn eq 'Whois') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='rrp' if (!defined($type) || ref($type));
 return ('Net::DRI::Transport::Socket',$ta,'Net::DRI::Protocol::RRP',$pa) if ($type eq 'rrp');
 return ('Net::DRI::Transport::Socket',[{%Net::DRI::DRD::PROTOCOL_DEFAULT_WHOIS,remote_host=>'whois.nic.ws'}],'Net::DRI::Protocol::Whois',[]) if (lc($type) eq 'whois');
}

####################################################################################################
1;
