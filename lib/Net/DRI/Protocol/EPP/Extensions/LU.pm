## Domain Registry Interface, DNSLU EPP extensions
##
## Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::LU;
use Net::DRI::Protocol::EPP::Extensions::LU::Status;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU - DNSLU EPP extensions for Net::DRI

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

Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################
sub new
{
 my ($c,$drd,$version,$extrah)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 $e{'Net::DRI::Protocol::EPP::Extensions::LU::Domain'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::LU::Contact'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::LU::Poll'}=1;

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]);
 $self->ns({dnslu => ['http://www.dns.lu/xml/epp/dnslu-1.0','dnslu-1.0.xsd']});
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .LU contacts
 $self->capabilities('contact_update','disclose',['add','del']);
 $self->capabilities('host_update','status',undef);
 $self->capabilities('domain_update','registrant',undef); ## a trade is needed
 $self->capabilities('domain_update','auth',undef); ## not used
 $self->factories('contact',sub { return Net::DRI::Data::Contact::LU->new(); });
 $self->factories('status',sub { return Net::DRI::Protocol::EPP::Extensions::LU::Status->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' }, duration => undef } }); ## authInfo and period not used
 return $self;
}

####################################################################################################
1;
