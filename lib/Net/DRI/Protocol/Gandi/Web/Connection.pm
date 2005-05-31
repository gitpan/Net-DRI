## Domain Registry Interface, Gandi Web Connection handling
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

package Net::DRI::Protocol::Gandi::Web::Connection;

use strict;
use Net::DRI::Exception;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Gandi::Web::Connection - Gandi Web Connection handling for Net::DRI

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


sub sleep ## delay between 2 queries
{
 sleep(2);
}

sub login
{
 shift if ($_[0] eq __PACKAGE__);
 my ($self)=@_; ## a Net::DRI::Transport::Web object
 my $wm=$self->wm();

 ## Default choice not optimal if many domains !
 ## (prefer direct link to admin/mod if that is what we want)
 my $url='https://www.gandi.net/admin/lsdom?l=fr';
 $wm->get($url);

 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry for authentication form') unless $wm->success();

 my $rc=$self->creds();

 Net::DRI::Exception->die(0,'transport',4,'Unable to login, no handle & pass provided') unless ($rc && ref($rc) && exists($rc->{handle}) && exists($rc->{pass}));

 __PACKAGE__->sleep();
 $wm->form_number(1);
 $wm->field('id',$rc->{handle});
 $wm->field('pass',$rc->{pass});
 $wm->click('login');

 Net::DRI::Exception->die(0,'transport',4,'Unable to send message to registry for authentication results') unless $wm->success();

 my $c=$wm->content();

 Net::DRI::Exception->die(0,'transport',6,'Invalid credentials') if ($c=~m/(Paramètres invalides|Identifiant inconnu|Mot de passe incorrect)/);

 Net::DRI::Exception->die(0,'transport',7,'Unable to find list of domains (page change ?)') unless ($c=~m/Liste des domaines pour un identifiant/);
 
 my %h=map { $_->url()=~m/&dom=(\S+)&mod=1/; lc($1) => $_->url() } grep { $_->text() eq 'Modifications' } $wm->links();
 return { urls => \%h };
}

sub logout
{
 shift if ($_[0] eq __PACKAGE__);
 my ($self)=@_; ## a Net::DRI::Transport::Web object

 ## nothing to do
}


#####################################################################################################################
1;
