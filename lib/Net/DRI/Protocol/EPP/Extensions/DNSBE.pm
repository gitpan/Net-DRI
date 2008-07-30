## Domain Registry Interface, DNSBE EPP extensions
##
## Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::DNSBE;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::BE;
use Net::DRI::Protocol::EPP::Extensions::DNSBE::Message;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNSBE - DNSBE (.BE) EPP extensions for Net::DRI

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

Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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

 $e{'Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::DNSBE::Contact'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::NSgroup'}=1;

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]);
 $version=$self->version(); ## make sure it is correctly set
 $self->ns({ dnsbe   => ['http://www.dns.be/xml/epp/dnsbe-1.0','dnsbe-1.0.xsd'],
             nsgroup => ['http://www.dns.be/xml/epp/nsgroup-1.0','nsgroup-1.0.xsd'],
          });
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .BE domains/contacts
 $self->capabilities('domain_update','status',undef);
 $self->capabilities('domain_update','auth',undef); ## No change in authinfo (since it is not used from the beginning)
 $self->capabilities('domain_update','nsgroup',['add','del']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::BE->new()->srid('ABCD') });
 $self->factories('message',sub { my $m=Net::DRI::Protocol::EPP::Extensions::DNSBE::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m;});
 $self->default_parameters({domain_create => { auth => { pw => '' } } });
 return $self;
}

sub core_contact_types { return ('admin','tech','billing','onsite'); }

####################################################################################################
1;
