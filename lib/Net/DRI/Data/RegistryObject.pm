## Domain Registry Interface, RegistryObject (experimental API)
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

package Net::DRI::Data::RegistryObject;

use strict;
use Net::DRI::Exception;

our $AUTOLOAD;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

## instead of
## $ndr->process('domain','add',[$domain,$ns,$period],[]);
## we can do
## $o=Net::DRI::Data::RegistryObject->new($ndr,'domain',$domain);
## $o->add([$ns,$period],[]); // or $o->add($ns,$period);
##
## $ndr can be $dri too

=pod

=head1 NAME

Net::DRI::Data::RegistryObject - Experimental API for Net::DRI operations

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


###########################################################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self={ 
            p    => $_[0], ## ndr or dri
            type => $_[1],
            name => $_[2], ## not always defined
          };

 bless($self,$class);
 return $self;
}

sub AUTOLOAD
{
 my $self=shift;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my ($ra1,$ra2);
 if (@_==2 && ref($_[0]) && ref($_[1]))
 {
  $ra1=$_[0];
  $ra1=[ $self->{name}, @$ra1 ] if (exists($self->{name}) && $self->{name});
  $ra2=$_[1];
 } else
 {
  $ra1=(exists($self->{name}) && $self->{name})? [$self->{name},@_] : [@_];
  $ra2=[];
 }

 my $ndr;
 if (ref($self->{p}) eq 'Net::DRI::Registry')
 {
  return $self->{p}->process($self->{type},$attr,$ra1,$ra2);
 } elsif (ref($self->{p}) eq 'Net::DRI')
 {
  my $c=$self->{type}."_".$attr;
  return $self->{p}->$c->(@$ra1);
 } else
 {
  Net::DRI::Exception::err_assert("case not handled: ".ref($self->{p}));
 }
}

###########################################################################################################
1;
