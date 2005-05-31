## Domain Registry Interface, AFNIC WS Message
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

package Net::DRI::Protocol::AFNIC::WS::Message;

use strict;

use Net::DRI::Protocol::ResultStatus;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version service method params result errcode));

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::WS::Message - AFNIC WebService Message for Net::DRI

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

our %CODES; ## defined at bottom

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self={errcode => undef};
 bless($self,$class);

 $self->params([]); ## default
 my $rh=shift;
 if (defined($rh) && (ref($rh) eq 'HASH'))
 {
  $self->service($rh->{service}) if exists($rh->{service});
  $self->method($rh->{method})   if exists($rh->{method});
  $self->params($rh->{params})   if exists($rh->{params});
 }
 return $self;
}

sub as_string { return undef; }

sub parse
{
 my ($self,$r)=@_;

 $self->result($r);
 my $c;
 $c=$r->{reason} if (defined($r) && ref($r) && exists($r->{reason}));
 $self->errcode($c);

 ## Warning: when we handle multiple web services, we will need a way to retrieve the method name called,
 ## to find the correct errcode, as it will obviously not be done the same way accross all services.
}

sub is_success { return 0; } ## because, it is either an error, or the domain does not exist (which is a 2xxx in EPP)

sub result_status
{
 my $self=shift;
 my $r=$self->result();
 return Net::DRI::Protocol::ResultStatus->new_error(2303,$r->{message}) if ($r->{free});
 return Net::DRI::Protocol::ResultStatus->new('afnic_ws_check_domain',$self->errcode(),\%CODES,$self->is_success(),$r->{message});
 ## Warning: when we handle multiple web services, we will need a way to retrieve the method name called,
 ## to find the correct key of the %CODES hash (and special case of free <=> 2303)
}

########################################################################

sub get_name_from_message
{
 my ($self)=@_;
 my $c=$self->method();
 my $rp=$self->params();

 return $rp->[0] if ($c eq 'check_domain');
}

#############################################################################################


%CODES=( 'afnic_ws_check_domain' =>
          {
           0   => 2400, # problème de connexion à la base de données => Command failed
           1   => 2302, # le nom de domaine est déjà enregistré => Object exists
           2   => 2308, # refusé car un nom de domaine équivalent existe déjà sous .fr ou sous .re => Data management policy violation
           4   => 2304, # une opération est en cours pour ce nom de domaine => Object status prohibits operation
           5   => 2308, # nom de domaine interdit (faisant partie de la liste des termes fondamentaux) => Data management policy violation
           100 => 2005, # mauvaise syntaxe du nom de domaine => Parameter value syntax error
          },
       );

########################################################################
1;
