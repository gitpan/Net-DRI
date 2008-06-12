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

use Net::DRI::Protocol::EPP::Message;
use Net::DRI::Data::Contact::Nominet;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

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
 my $c=shift;
 my ($drd,$version,$extrah)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 my @c=map { 'Net::DRI::Protocol::EPP::Extensions::Nominet::'.$_ } qw/Domain Contact Host Account/;
 push @c,'Session';
 my $self=$c->SUPER::new($drd,$version,[keys(%e)],\@c); ## we are now officially a Net::DRI::Protocol::EPP object

 foreach my $w (qw/domain contact ns account notifications/)
 {
  $self->{ns}->{$w}=['http://www.nominet.org.uk/epp/xml/nom-'.$w.'-1.0','nom-'.$w.'-1.0.xsd'];
 }

 my $rcapa=$self->capabilities();
 $rcapa->{domain_update}={ map { $_ => ['set'] } qw/ns contact first-bill recur-bill auto-bill next-bill notes/ };
 $rcapa->{contact_update}={ info => ['set'] };
 $rcapa->{host_update}={ ip => ['set'], name => ['set'] };
 $rcapa->{account_update}={ contact => ['set'] };

 my $rfact=$self->factories();
 $rfact->{contact}=sub { return Net::DRI::Data::Contact::Nominet->new(); };
 $rfact->{message}=sub { my $m=Net::DRI::Protocol::EPP::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m;}; ## needed for change of XML NS

 $self->default_parameters({domain_create => { auth => { pw => '' } } }); ## domain:authInfo is not used by Nominet

 bless($self,$c); ## rebless
 return $self;
}

sub core_contact_types { return ('admin','billing'); } ## not really used

####################################################################################################
1;
