## Domain Registry Interface, EURid EPP extensions
##
## Copyright (c) 2005,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::EURid;
use Net::DRI::Protocol::EPP::Extensions::EURid::Message;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid - EURid (.EU) EPP extensions for Net::DRI

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

Copyright (c) 2005,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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

 $e{'Net::DRI::Protocol::EPP::Extensions::EURid::Domain'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::EURid::Contact'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::NSgroup'}=1;
 ## Sunrise should be added when calling, as it is not mandatory

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]);
 $version=$self->version(); ## make sure it is correctly set

 $self->ns({_main => ['http://www.eurid.eu/xml/epp/epp-1.0','epp-1.0.xsd']});
 foreach my $w ('domain','contact','eurid','nsgroup')
 {
  $self->ns({ $w => ['http://www.eurid.eu/xml/epp/'.$w.'-1.0',$w.'-1.0.xsd'] });
 }
 $self->capabilities('contact_update','status',undef); ## No changes in status possible for .EU domains/contacts
 $self->capabilities('domain_update','status',undef);
 $self->capabilities('domain_update','nsgroup',[ 'add','del']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::EURid->new()->srid('ABCD') });
 $self->factories('message',sub { my $m=Net::DRI::Protocol::EPP::Extensions::EURid::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m;} );
 $self->default_parameters({domain_create => { auth => { pw => '' } } });
 return $self;
}

sub core_contact_types { return ('admin','tech','billing','onsite'); }

####################################################################################################
1;
