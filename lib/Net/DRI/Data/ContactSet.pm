## Domain Registry Interface, Stores ordered list of contacts + type (registrant, admin, tech, bill, etc...)
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


package Net::DRI::Data::ContactSet;

use strict;

#our @TYPES=('registrant','admin','tech','billing'); ## default list of types

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::ContactSet - Handle an ordered collection of contacts for Net::DRI

=head1 DESCRIPTION

This class encapsulates a set of contacts, with associated types. For each type, it can stores as many contacts as needed.
Contacts are compared among themselves by calling the id() method on them. Thus all Contact classes
must define such a method, which returns a string.

=over

=item *

C<new()> creates a new object

=item *

C<types()> returns the list of current types stored in this class

=item *

C<has_type()> returns 1 if the given type as first argument has some contacts in this object, 0 otherwise

=item *

C<add()> with the first argument being a contact, and the second (optional) a type, adds the contact
to the list of contacts for this type or all types (if no second argument). If the contact already exists
(same id()), it will be replaced when found

=item *

C<del()> the opposite of add()

=item *

C<clear()> removes all contact currently associated to all types

=item *

C<set()> with an array ref as first argument, and a type (optional) as second, set the current list
of the given type (or all types) to be the list of contacts in first argument

=item *

C<get()> returns list (in list context) or first element of list (in scalar context) for the type given as argument

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

################################################################################################################
sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self={};
# $self->{c}={ map { $_ => [] } @TYPES };
 $self->{c}={};
 bless($self,$class);
}

sub types
{
 my ($self)=@_;
 return sort(grep { @{$self->{c}->{$_}} } keys(%{$self->{c}}));
}

sub has_type
{
 my ($self,$ctype)=@_;
 return 0 unless defined($ctype);
 return exists($self->{c}->{$ctype});
}

sub is_empty
{
 my $self=shift;
 my @a=$self->types();
 return (@a)? 0 : 1;
}

sub _pos
{
 my ($self,$t,$id)=@_;
 my $c=$self->{c};
 my $l=$#{$c->{$t}};
 my @p=grep { $c->{$t}->[$_]->id() eq $id } (0..$l);
 return (@p)? $p[0] : undef;
}

sub add
{
 my ($self,$cobj,$ctype)=@_;
 return unless defined($cobj);
 my $c=$self->{c};
 $c->{$ctype}=[] if (defined($ctype) && !exists($c->{$ctype}));
 my $id=$cobj->id();
 foreach my $k (keys(%$c))
 {
  next if (defined($ctype) && ($k ne $ctype));
  my $p=$self->_pos($k,$id);
  if (defined($p))
  {
   $c->{$k}->[$p]=$cobj;
  } else
  {
   push @{$c->{$k}},$cobj;
  }
 }
}

sub del
{
 my ($self,$cobj,$ctype)=@_;
 return unless defined($ctype);
 my $c=$self->{c};
 return if (defined($ctype) && !exists($c->{$ctype}));
 my $id=$cobj->id();
 foreach my $k (keys(%$c))
 {
  next if (defined($ctype) && ($k ne $ctype));
  my $p=$self->_pos($k,$id);
  next unless defined($p);
  splice(@{$c->{$k}},$p,1);
 }
}

sub clear
{
 my ($self,$ctype)=@_;
 return $self->set($ctype,[]);
}

sub set
{
 my ($self,$robj,$ctype)=@_;
 return unless defined($robj);
 my $c=$self->{c};
 $c->{$ctype}=[] if (defined($ctype) && !exists($c->{$ctype}));
 foreach my $k (keys(%$c))
 {
  next if (defined($ctype) && ($k ne $ctype));
  $c->{$k}=(ref($robj) eq 'ARRAY')? $robj : [$robj];
 }
}

sub get
{
 my ($self,$ctype)=@_;
 return undef unless defined($ctype);
 my $c=$self->{c};
 return undef unless exists($c->{$ctype});
 return wantarray()? @{$c->{$ctype}} : $c->{$ctype}->[0];
}

sub match ## compare two contact lists
{
 my ($self,$other)=@_;
 return 0 unless (defined($other) && (ref($other) eq ref($self)));
 my $c1=$self->{c};
 my $c2=$other->{c};
 return 0 unless (keys(%$c1)==keys(%$c2));
 return 0 if grep { ! exists($c1->{$_}) } keys(%$c2);
 return 0 if grep { ! exists($c2->{$_}) } keys(%$c1);
 foreach my $k (keys(%$c1))
 {
  my %tmp1=map { $_->id() => 1 } @{$c1->{$k}};
  my %tmp2=map { $_->id() => 1 } @{$c2->{$k}};
  return 0 if grep { ! exists($tmp2{$_}) } keys(%tmp1);
  return 0 if grep { ! exists($tmp1{$_}) } keys(%tmp2);
 }

 return 1;
}

sub has_contact
{
 my ($self,$cobj,$ctype)=@_;
 return 0 unless defined($cobj);
 my $c=$self->{c};
 return 0 if (defined($ctype) && !exists($c->{$ctype}));
 my $id=(ref($cobj))? $cobj->id() : $cobj;
 foreach my $k (keys(%$c))
 {
  next if (defined($ctype) && ($k ne $ctype));
  return 1 if defined($self->_pos($k,$id));
 }
 return 0;
}

##############################################################################
1;
