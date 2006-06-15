## Domain Registry Interface, NASK (.PL) EPP extensions (draft-zygmuntowicz-epp-pltld-03)
##
## Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::PL;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL - .PL EPP extensions (draft-zygmuntowicz-epp-pltld-03) for Net::DRI

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

Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>.
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

 $e{'Net::DRI::Protocol::EPP::Extensions::PL::Domain'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::PL::Contact'}=1;
## $e{'Net::DRI::Protocol::EPP::Extensions::PL::Future'}=1; ## TODO

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]); ## we are now officially a Net::DRI::Protocol::EPP object

 $self->{ns}->{pl_domain}=['urn:nask:params:xml:ns:extdom-1.0','extdom-1.0.xsd'];
 $self->{ns}->{pl_contact}=['urn:nask:params:xml:ns:extcon-1.0','extcon-1.0.xsd'];
## $self->{ns}->{future}=['http://www.dns.pl/NASK-EPP/future-1.0','future-1.0.xsd'];

 my $rcapa=$self->capabilities();
 delete($rcapa->{host_update}->{name}); ## No change of hostnames

 my $rfact=$self->factories();
 $rfact->{contact}=sub { return Net::DRI::Data::Contact::PL->new(); };

 bless($self,$c); ## rebless
 return $self;
}

####################################################################################################
1;
