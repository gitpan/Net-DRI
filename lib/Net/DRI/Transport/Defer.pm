## Domain Registry Interface, Deferred Transport
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

package Net::DRI::Transport::Defer;

use base qw(Net::DRI::Transport);

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::Defer - Deferred Transport for Net::DRI

=head1 DESCRIPTION

This module implements a deferred transport in Net::DRI. For now it just dumps all data
to a given filehandle, and reports back to Net::DRI that the message has been sent.

This is useful for debugging, and also to validate all parameters of an operation without
actually sending anything to the registry ; in such way, it is kind of a « simulate » operation
where everything is done (parameters validation, message building, etc...) without touching
the registry.

=head1 METHODS

At creation (see Net::DRI C<new_profile>) you pass a reference to an hash, with the following available keys:

=head2 protocol_connection

Net::DRI class handling protocol connection details. (Ex: C<Net::DRI::Protocol::RRP::Connection> or C<Net::DRI::Protocol::EPP::Connection>)

=head2 dump_fh (optional)

a filehandle (ex: \*STDERR or an anonymous filehandle) on something already opened for write ;
if not defined, defaults to \*STDERR

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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
 my $class=shift;
 my $drd=shift;
 my $po=shift;

 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts);
 $self->name('defer');
 $self->version('0.1');
 $self->has_state(0);
 $self->is_sync(0);
 $self->defer(0);
 $self->current_state(0);
 $self->time_open(time());
 $self->time_used(time());

 my %t=(exchanges_done => 0);
 $t{dump_fh}=(exists($opts{dump_fh}))? $opts{dump_fh} : \*STDERR;

 Net::DRI::Exception::usererr_insufficient_parameters('protocol_connection') unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};
 $t{pc}->require or Net::DRI::Exception::err_failed_load_module('transport/socket',$t{pc},$@);
 my @need=qw/read_data write_message/;
 Net::DRI::Exception::usererr_invalid_parameters('protocol_connection class ('.$t{pc}.') must have: '.join(' ',@need)) if (grep { ! $t{pc}->can($_) } @need);

 $self->{transport}=\%t;
 return $self;
}

sub is_compatible_with_protocol { my ($self,$po)=@_; return 1; }
sub ping {  return 1; }

sub send
{
 my ($self,$trid,$tosend)=@_;
 my $t=$self->transport_data();
 my $pc=$t->{pc};

 print { $t->{dump_fh} } "\n",$pc->write_message($self,$tosend),"\n";
 return 1;
}

####################################################################################################
1;
