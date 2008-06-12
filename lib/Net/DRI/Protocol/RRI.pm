## Domain Registry Interface, RRI Protocol (DENIC-11)
##
## Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::RRI;

use strict;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Protocol::RRI::Message;
use Net::DRI::Data::StatusList;
use Net::DRI::Data::Contact::DENIC;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRI - RRI Protocol (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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

 my $self=$c->SUPER::new(); ## we are now officially a Net::DRI::Protocol object
 $self->name('RRI');
 $version=Net::DRI::Util::check_equal($version,['2.0'],'2.0');
 $self->version($version);

 $self->capabilities({ 'host_update'   => { 'ip' => ['add','del'], 'status' => ['add','del'], 'name' => ['set'] },
                       'contact_update'=> { 'info' => ['set'] },
                       'domain_update' => { 'ns' => ['add','del'], 'status' => ['add','del'], 'contact' => ['add','del'], 'registrant' => ['set'], 'auth' => ['set'] },
                     });

 $self->{ns}={ _main	=> ['http://registry.denic.de/global/1.0'],
		tr	=> ['http://registry.denic.de/transaction/1.0'],
		contact	=> ['http://registry.denic.de/contact/1.0'],
		domain	=> ['http://registry.denic.de/domain/1.0'],
		dnsentry=> ['http://registry.denic.de/dnsentry/1.0'],
                msg	=> ['http://registry.denic.de/msg/1.0'],
		xsi	=> ['http://www.w3.org/2001/XMLSchema-instance'],
 };

 $self->factories({ 
                   message => sub { my $m=Net::DRI::Protocol::RRI::Message->new(@_); $m->ns($self->{ns}); $m->version($version); return $m; },
                   status  => sub { return Net::DRI::Data::StatusList->new(); },
                   contact => sub { return Net::DRI::Data::Contact::DENIC->new(); },
                  });

 bless($self,$c); ## rebless

 $self->_load($extrah);
 return $self;
}

sub _load
{
 my ($self,$extrah)=@_;

 my @core=('Session','RegistryMessage','Domain','Contact');
 my @class=map { 'Net::DRI::Protocol::RRI::'.$_ } @core;

 $self->SUPER::_load(@class);
}

####################################################################################################
1;
