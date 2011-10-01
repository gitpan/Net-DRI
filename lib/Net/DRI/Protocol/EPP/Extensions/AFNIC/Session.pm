## Domain Registry Interface, AFNIC EPP Session commands
##
## Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Session;

use strict;
use warnings;

use Net::DRI::Exception;
use Net::DRI::Util;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Session - AFNIC EPP Session commands for Net::DRI

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

Copyright (c) 2011 Patrick Mevzek <netdri@dotandco.com>.
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
          'connect' => [ undef, \&parse_greeting ],
           noop     => [ undef, \&parse_greeting ], ## for keepalives
         );

 return { 'session' => \%tmp };
}

sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $g=$mes->node_greeting();
 return unless $mes->is_success() && defined $g; ## make sure we are not called for all parsing operations (after poll), just after true greeting

 my $rserver=$rinfo->{session}->{server};
 my $ns=$mes->ns('frnic');

 return unless grep { $_ eq $ns } @{$rserver->{extensions_selected}}; ## no point going further if version changes, login will die anyway
 return unless ( grep { m!/frnic-\d\.\d$! } @{$rserver->{extensions_selected}} ) > 1; ## nothing extra to do if only one version announced & correct one!


 my %ctxlog=(action=>'greeting',direction=>'in',trid=>$mes->cltrid());
 $po->log_output('info','protocol',{%ctxlog,message=>sprintf('More than one frnic extension announced by server, selecting "%s"',$ns)});
 $rserver->{extensions_selected}=[ grep { ! m!/frnic-\d\.\d$! || $_ eq $ns } @{$rserver->{extensions_selected}} ];
}

####################################################################################################
1;
