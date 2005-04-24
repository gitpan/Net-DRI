## Domain Registry Interface, Handling of statuses list (order is irrelevant) (virtual class)
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

package Net::DRI::Data::StatusList;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d"."%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::StatusList - Handle a collection of statuses for an object, in a registry independent fashion

=head1 DESCRIPTION

You should never have to use this class directly, but you may get back objects that
are instances of subclasses of this class. An object of this class can store the statuses' names,
with a message for each and a language tag, and any other stuff, depending on registry.

You can call the following methods:

=over

=item *

C<is_active()> returns 1 if these statuses enable an object to be active

=item *

C<is_publised()> returns 1 if these statuses enable the object to be published on registry DNS servers

=item *

C<is_pending()> returns 1 if theses statuses are for an object that is pending some action at registry

=item *

C<is_linked()> returns 1 if theses statuses are for an object that is linked to another one at registry

=item *

C<can_update()> returns 1 if theses statuses allow to update the object at registry

=item *

C<can_transfer()> returns 1 if theses statuses allow to transfer the object at registry

=item *

C<can_delete()> returns 1 if theses statuses allow to delete the object at registry

=item *

C<can_renew()> returns 1 if theses statuses allow to renew the object at registry

=back

You may also use the following methods, but they should be less useful as
the purpose of the module is to give an abstract view of the underlying statuses.

=over

=item *

C<list_status()> to get only the statuses' names (always in uppercase)

=item *

C<has_any()> returns 1 if the object has any of the statuses given as arguments

=item *

C<has_not()> returns 1 if the object has none of the statuses given as arguments

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

 my $pname=shift || '?';
 my $pversion=shift || '?';

 my $self={ proto_name    => $pname,
            proto_version => $pversion,
            sl => {}, ## uc(statusname) => { lang => lc(lang), msg => '', other per class }
          };

 bless($self,$class);
 $self->add(@_) if (@_);
 return $self;
}

sub add
{
 my $self=shift;
 my $rs=$self->{sl};
 
 foreach my $el (@_)
 {
  if (ref($el))
  {
   my %tmp=%{$el};
   my $name=$tmp{name};
   delete($tmp{name});
   $rs->{uc($name)}=\%tmp;
  } else
  {
   $rs->{uc($el)}={};
  }
 }
}

sub list_status
{
 my $self=shift;
 return keys(%{$self->{sl}});
}

sub is_empty
{
 my $self=shift;
 return ($self->list_status() > 0)? 0 : 1;
}

sub has_any
{
 my $self=shift;
 foreach my $el (@_)
 {
  return 1 if exists($self->{sl}->{uc($el)});
 }
 return 0;
}

sub has_not
{
 my $self=shift;
 foreach my $el (@_)
 {
  return 0 if exists($self->{sl}->{uc($el)})
 }
 return 1;
}

###########################################################################################################
## Methods that must be defined in subclasses

sub is_active    { Net::DRI::Exception::err_method_not_implemented("is_active in ".ref($_[0])); }
sub is_published { Net::DRI::Exception::err_method_not_implemented("is_published in ".ref($_[0])); } 
sub is_pending   { Net::DRI::Exception::err_method_not_implemented("is_pending in ".ref($_[0])); }
sub is_linked    { Net::DRI::Exception::err_method_not_implemented("is_linked in ".ref($_[0])); }
sub can_update   { Net::DRI::Exception::err_method_not_implemented("can_update in ".ref($_[0])); }
sub can_transfer { Net::DRI::Exception::err_method_not_implemented("can_transfer in ".ref($_[0])); }
sub can_delete   { Net::DRI::Exception::err_method_not_implemented("can_delete in ".ref($_[0])); }
sub can_renew    { Net::DRI::Exception::err_method_not_implemented("can_renew in ".ref($_[0])); }

###########################################################################################################
1;
