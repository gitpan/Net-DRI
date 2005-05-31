## Domain Registry Interface, Encapsulating raw data
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

package Net::DRI::Data::Raw;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::Raw - Encapsulating raw data for Net::DRI

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


######################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my ($type,$data)=@_;

## type=1, data=ref to array
## type=2, data=string
## type=3, data=ref to string NOTIMPL
## type=4, data=path to local file NOTIMPL
## type=5, data=object with a as_string method NOTIMPL

 my $self={type => $type,
           data => $data,
          };

 bless($self,$class);
 return $self;
}


sub new_from_array  
{
 my $class=shift;
 my @a=map { s/\r?\n$//; $_; } (ref($_[0]))? @{$_[0]} : @_;
 return $class->new(1,\@a);
}

sub new_from_string { return shift->new(2,shift); }

##########################################################################

sub type { return shift->{type}; }
sub data { return shift->{data}; }

##########################################################################

sub as_string
{
 my $self=shift;
 my $data=$self->data();

 if ($self->type()==1)
 {
  return join("\n",@$data)."\n";
 }
 if ($self->type()==2)
 {
  $data=~s/\r\n/\n/g;
  return $data;
 }
}

sub last_line
{
 my $self=shift;

 if ($self->type()==1)
 {
  my $data=$self->data();
  return $data->[$#$data]; ## see above
 }
 if ($self->type()==2)
 {
  my @a=$self->as_array();
  return $a[-1];
 }
}

sub as_array
{
 my $self=shift;

 if ($self->type()==1)
 {
  return @{$self->data()};
 }

 if ($self->type()==2)
 {
  return split(/\r?\n/,$self->data());
 }
}

##########################################################################
1;