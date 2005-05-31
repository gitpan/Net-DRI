## Domain Registry Interface, Gandi Web Scraping Message
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

package Net::DRI::Protocol::Gandi::Web::Message;

use strict;

use Net::DRI::Protocol::ResultStatus;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version method params oname otype command result errcode errmsg pagecontent));

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Gandi::Web::Message - Gandi Web Scraping Message for Net::DRI

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

 my $self={errcode => undef, errmsg=> ''};
 bless($self,$class);

 $self->params([]); ## default
 my $rh=shift;
 if (defined($rh) && (ref($rh) eq 'HASH'))
 {
  $self->method($rh->{method})   if exists($rh->{method});
  $self->params($rh->{params})   if exists($rh->{params});
 }
 return $self;
}

sub as_string { return undef; }

sub parse
{
 my ($self,$wm)=@_;
 $self->pagecontent($wm->content());
}

sub is_success
{ 
 my $self=shift;
 my $errcode=$self->errcode();
 return (defined($errcode) && $errcode==1000)? 1 : 0;
}

sub result_status
{
 my $self=shift;
 return Net::DRI::Protocol::ResultStatus->new('epp',$self->errcode(),undef,$self->is_success(),$self->errmsg());
}

sub get_name_from_message
{
 my ($self)=@_;
 return $self->oname();
}

#################################################################################################
1;
