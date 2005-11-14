## Domain Registry Interface, EPP Protocol (RFC 3730,3731,3732,3733,3734,3735)
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

package Net::DRI::Protocol::EPP;

use strict;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;

use Net::DRI::Protocol::EPP::Message;
use Net::DRI::Protocol::EPP::Core::Status;
use Net::DRI::Data::Contact;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP - EPP Protocol (RFC 3730,3731,3732,3733,3734,3735) for Net::DRI

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

###############################################################################

sub new
{
 my $h=shift;
 my $c=ref($h) || $h;

 my ($drd,$version,$extrah)=@_;

 my $self=$c->SUPER::new(); ## we are now officially a Net::DRI::Protocol object
 $self->name('EPP');
 $version=Net::DRI::Util::check_equal($version,['1.0'],'1.0');
 $self->version($version);

 $self->capabilities({ 'host_update'   => { 'ip' => ['add','del'], 'status' => ['add','del'], 'name' => ['set'] },
                       'contact_update'=> { 'status' => ['add','del'], 'info' => ['set'] },
                       'domain_update' => { 'ns' => ['add','del'], 'status' => ['add','del'], 'contact' => ['add','del'], 'registrant' => ['set'], 'auth' => ['set'] },
                     });

 $self->{hostasattr}=$drd->info('host_as_attr') || 0;
 $self->{ns}={ _main   => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'],
               domain  => ['urn:ietf:params:xml:ns:domain-1.0','domain-1.0.xsd'],
               host    => ['urn:ietf:params:xml:ns:host-1.0','host-1.0.xsd'],
               contact => ['urn:ietf:params:xml:ns:contact-1.0','contact-1.0.xsd'],
             };

 $self->factories({ 
                   message => sub { my $m=Net::DRI::Protocol::EPP::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m; },
                   status  => sub { return Net::DRI::Protocol::EPP::Core::Status->new(); },
                   contact => sub { return Net::DRI::Data::Contact->new(); },
                  });

 bless($self,$c); ## rebless

 $self->_load($extrah);
 return $self;
}

sub _load
{
 my ($self,$extrah)=@_;

 my @core=('Session','Domain','Contact');
 push @core,'Host' unless $self->{hostasattr};
 my @class=map { "Net::DRI::Protocol::EPP::Core::".$_ } @core;
 if (defined($extrah) && $extrah)
 {
  push @class,map { /::/? $_ : "Net::DRI::Protocol::EPP::Extensions::".$_ } (ref($extrah)? @$extrah : ($extrah));
 }

 $self->SUPER::_load(@class);
}

sub server_greeting { my ($self,$v)=@_; $self->{server_greeting}=$v if $v; return $self->{server_greeting}; }

sub parse_status
{
 my $node=shift;
 my %tmp;
 $tmp{name}=$node->getAttribute('s');
 $tmp{lang}=$node->getAttribute('lang') || 'en';
 $tmp{msg}=$node->firstChild()->getData() if ($node->firstChild());
 return \%tmp;
}

############################################################################################
1;
