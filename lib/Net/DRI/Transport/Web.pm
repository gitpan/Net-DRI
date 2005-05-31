## Domain Registry Interface, Web Scraping Transport
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

package Net::DRI::Transport::Web;

use strict;

use base qw/Net::DRI::Transport/;

use WWW::Mechanize;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Transport::Web - Web Scraping for Net::DRI

=head1 DESCRIPTION

The following options are available at creation:

=over

=item *

C<timeout> : time to wait (in seconds) for server reply

=item *

C<protocol_connection> : Net::DRI class handling protocol connection details.

=item *

C<credentials> : hashref with handle and pass keys (for Gandi scraping, will depend on web site used)

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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

####################################################################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $drd=shift;
 my %opts=(@_==1 && ref($_[0]))? %{$_[0]} : @_;
 my $self=$class->SUPER::new(\%opts); ## We are now officially a Net::DRI::Transport instance
 $self->has_state(1);
 $self->is_sync(1);
 $self->name('web');
 $self->version($VERSION);

 my %t;
 $t{wm}=WWW::Mechanize->new( cookie_jar => {},
                             agent      => exists($opts{agent})? $opts{agent} : "Net::DRI::Transport::Web (${VERSION})",
                             quiet      => 1, ## thus no onwarn
                             onerror    => sub { Net::DRI::Exception->die(1,"transport",0,"Error not handled: $@") },
                           );

 Net::DRI::Exception::usererr_insufficient_parameters("protocol_connection") unless (exists($opts{protocol_connection}) && $opts{protocol_connection});
 $t{pc}=$opts{protocol_connection};

 my @needed=('login','logout','sleep');
 eval "require $t{pc}";
 Net::DRI::Exception::usererr_invalid_parameters("protocol_connection class must have: ".join(" ",@needed)) if (grep { ! $t{pc}->can($_) } @needed);

 $t{creds}=exists($opts{credentials})? $opts{credentials} : {};
 $self->{transport}=\%t;
 bless($self,$class); ## rebless in my class

 if ($self->defer()) ## we will open, but later
 {
  $self->current_state(0);
 } else ## we will open NOW
 {
  $self->open_connection();
  $self->current_state(1);
 }

 return $self;
}

sub wm    { return shift->{transport}->{wm}; }
sub pc    { return shift->{transport}->{pc}; }
sub creds { return shift->{transport}->{creds}; }
sub ctx   { return shift->{transport}->{ctx}; }

sub open_connection
{
 my ($self)=@_;
 $self->{transport}->{ctx}=$self->pc()->login($self);
 $self->current_state(1);
 $self->time_open(time());
 $self->{transport}->{exchanges_done}=0;
}

sub close_connection
{
 my ($self)=@_;
 $self->wm()->cookie_jar({}); ## we reset the cookie jar
 $self->{transport}->{ctx}=undef;
 $self->current_state(0);
}

sub end
{
 my $self=shift;
 if ($self->current_state())
 {
  $self->close_connection();
 }
}

########################################################################################################################

sub send
{
 my ($self,$tosend)=@_;
 $self->SUPER::send($tosend,\&_webprint,sub {});
}

sub _webprint ## here we are sure open_connection() was called before
{
 my ($self,$count,$tosend)=@_;

 $self->pc()->sleep($self); ## make sure we do not send too fast

 my $met=$tosend->method();
 my $rp=$tosend->params();

 $met->($rp,$self);

 return 1; ## very important
}

sub receive
{
 my $self=shift;
 return $self->SUPER::receive(\&_web_receive);
}

sub _web_receive
{
 my ($self,$count)=@_;

 ## nothing to do ?

 return $self->wm(); 
}

####################################################################################################################
1;
