## Domain Registry Interface, EURid EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::EURid;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::EURid;
use Net::DRI::Protocol::EPP::Extensions::EURid::Message;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid - EURid EPP extensions for Net::DRI

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

####################################################################################################
sub new
{
 my $h=shift;
 my $c=ref($h) || $h;

 my ($drd,$version,$extrah)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 $e{'Net::DRI::Protocol::EPP::Extensions::EURid::Domain'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::EURid::Contact'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::NSgroup'}=1;
 ## Sunrise should be added when calling, as it is not mandatory

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]); ## we are now officially a Net::DRI::Protocol::EPP object

 $self->{ns}->{_main}=['http://www.eurid.eu/xml/epp/epp-1.0','epp-1.0.xsd'];
 foreach my $w ('domain','contact','eurid','nsgroup')
 {
  $self->{ns}->{$w}=['http://www.eurid.eu/xml/epp/'.$w.'-1.0',$w.'-1.0.xsd'];
 }

 my $rcapa=$self->capabilities();
 delete($rcapa->{contact_update}->{status}); ## No changes in status possible for .EU domains/contacts
 delete($rcapa->{domain_update}->{status});

 my $rfact=$self->factories();
 $rfact->{contact}=sub { return Net::DRI::Data::Contact::EURid->new()->srid('ABCD') };
 $rfact->{message}=sub { my $m=Net::DRI::Protocol::EPP::Extensions::EURid::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m;};

 $self->default_parameters({domain_create => { auth => { pw => '' } } });

 bless($self,$c); ## rebless
 return $self;
}

####################################################################################################
1;
