## Domain Registry Interface, Dummy transport for tests & debug
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

package Net::DRI::Transport::Dummy;

use base qw(Net::DRI::Transport);
use strict;

use Net::DRI::Data::Raw;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::Dummy - Net::DRI dummy transport for tests & debug

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



sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $drd=shift;
 my $rh=shift;

 my $self=$class->SUPER::new($rh); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(0);
 $self->is_sync(1);
 $self->name('dummy');
 $self->version('0.1');

 $self->{f_send}=(exists($rh->{f_send}))? $rh->{f_send} : \&_print;
 $self->{f_recv}=(exists($rh->{f_recv}))? $rh->{f_recv} : \&_got_ok;

 bless($self,$class); ## rebless in my class
 return $self;
}

sub is_compatible_with_protocol { return 1; }

sub send
{
 my $self=shift;
 my $tosend=shift;
 $self->SUPER::send($tosend,$self->{f_send});
}

sub _print
{
 my ($self,$count,$tosend)=@_;
 print STDOUT ">>>>>>>>>>>>>>>>>> (Net::DRI::Transport::Dummy) (count=$count)\n";
 print STDOUT $tosend->as_string();
 print STDOUT ">>>>>>>>>>>>>>>>>>\n\n";
 return 1; ## very important
}

sub receive
{
 my $self=shift;

 return $self->SUPER::receive($self->{f_recv});
}

sub _got_ok
{
 my ($self,$count)=@_;

 my $m="200 OK\r\n.\r\n";
 
 print STDOUT "<<<<<<<<<<<<<<<<<< (Net::DRI::Transport::Dummy) (count=$count)\n";
 print STDOUT $m;
 print STDOUT "<<<<<<<<<<<<<<<<<<\n\n";

 return Net::DRI::Data::Raw->new_from_string($m);
}

######################################################################################
1;
