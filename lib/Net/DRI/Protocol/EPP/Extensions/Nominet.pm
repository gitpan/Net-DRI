## Domain Registry Interface, .UK EPP extensions
## As seen on http://www.nominet.org.uk/registrars/systems/epp/ and http://www.nominet.org.uk/digitalAssets/16844_EPP_Mapping.pdf
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

package Net::DRI::Protocol::EPP::Extensions::Nominet;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

use Net::DRI::Data::Contact::Nominet;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::Nominet - .UK EPP extensions for Net::DRI

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

sub new
{
 my ($c,$drd,$version,$extrah)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 my @c=map { 'Net::DRI::Protocol::EPP::Extensions::Nominet::'.$_ } qw/Domain Contact Host Account Notifications/;
 push @c,'Session';
 push @c,'RegistryMessage';
 my $self=$c->SUPER::new($drd,$version,[keys(%e)],\@c);
 foreach my $w (qw/domain contact ns account notifications/)
 {
  $self->ns({$w => ['http://www.nominet.org.uk/epp/xml/nom-'.$w.'-1.1','nom-'.$w.'-1.1.xsd'] });
 }

 foreach my $o (qw/ns contact first-bill recur-bill auto-bill next-bill notes/) { $self->capabilities('domain_update',$o,['set']); }
 $self->capabilities('contact_update','info',['set']);
 $self->capabilities('host_update','ip',['set']);
 $self->capabilities('host_update','name',['set']);
 $self->capabilities('account_update','contact',['set']);
 $self->factories('contact',sub { return Net::DRI::Data::Contact::Nominet->new(); });
 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## domain:authInfo is not used by Nominet
 return $self;
}

sub core_contact_types { return ('admin','billing'); } ## not really used

####################################################################################################
1;
