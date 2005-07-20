## Domain Registry Interface, Handling of contact data
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


package Net::DRI::Data::Contact;

use strict;
use base qw(Class::Accessor::Chained::Fast); ## provides a new() method
__PACKAGE__->mk_accessors(qw(name org street city sp pc cc email voice fax loid roid srid auth disclose));

use Net::DRI::Exception;
use Net::DRI::Util;

use Email::Valid;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::Contact - Handle contact data, modeled from EPP for Net::DRI

=head1 DESCRIPTION

This base class encapsulates all data for a contact as defined in EPP (RFC3733).
It can (and should) be subclassed for TLDs needing to store other data for a contact.
All subclasses must have a validate() method that takes care of verifying contact data,
and an id() method returning an opaque value, unique per contact (in a given registry).

The following accessors/mutators can be called in chain, as they all return the object itself.

=over

=item *

C<loid()> local object ID for this contact, never sent to registry (can be used to track the local db id of this object)

=item *

C<srid()> server ID, ID of the object as known by the registry in which it was created

=item *

C<id()> an alias (needed for Net::DRI::Data::ContactSet) of the previous method

=item *

C<roid()> registry/remote object id (internal to a registry)

=item *

C<name()> name of the contact

=item *

C<org()> organization of the contact

=item *

C<street()> street address of the contact (ref array of up to 3 elements)

=item *

C<city()> city of the contact

=item *

C<sp()> state/province of the contact

=item *

C<pc()> postal code of the contact

=item *

C<cc()> country code of the contact

=item *

C<email()> email address of the contact

=item *

C<voice()> voice number of the contact (in the form +CC.NNNNNNNNxEEE)

=item *

C<fax()> fax number of the contact (same form as above)

=item *

C<auth()> authentification for this contact (hash ref with a key 'pw' and a value being the password)

=item *

C<disclose()> privacy settings related to this contact (see RFC)

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
## Needed for ContactSet
sub id { return shift->srid(@_); }

sub validate ## See RFC3733,§4
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 if (!$change)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('Invalid contact information: name/city/cc/email/auth/srid mandatory') unless ($self->name() && $self->city() && $self->cc() && $self->email() && $self->auth() && $self->srid());
  push @errs,'srid' unless Net::DRI::Util::xml_is_token($self->srid(),3,16);
 }

 push @errs,'roid' if ($self->roid() && $self->roid()!~m/^\w{1,80}-\w{1,8}$/); ## \w includes _ in Perl
 
 push @errs,'name' if ($self->name() && !Net::DRI::Util::xml_is_normalizedstring($self->name(),1,255));
 push @errs,'org'  if ($self->org()  && !Net::DRI::Util::xml_is_normalizedstring($self->org(),undef,255));

 my $rs=$self->street();
 push @errs,'street' if ($rs && (ref($rs) eq 'ARRAY') && (@$rs > 3) && (grep { !Net::DRI::Util::xml_is_normalizedstring($_,undef,255) } @$rs));

 push @errs,'city' if ($self->city() && !Net::DRI::Util::xml_is_normalizedstring($self->city(),1,255));
 push @errs,'sp'   if ($self->sp()   && !Net::DRI::Util::xml_is_normalizedstring($self->sp(),undef,255));
 push @errs,'pc'   if ($self->pc()   && !Net::DRI::Util::xml_is_token($self->pc(),undef,16));
 push @errs,'cc'   if ($self->cc()   && !Net::DRI::Util::xml_is_token($self->cc(),2,2));

 push @errs,'voice' if ($self->voice() && !Net::DRI::Util::xml_is_token($self->voice(),undef,17) && $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'fax'   if ($self->fax()   && !Net::DRI::Util::xml_is_token($self->fax(),undef,17)   && $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/);
 push @errs,'email' if ($self->email() && !Net::DRI::Util::xml_is_token($self->email(),1,undef) && !Email::Valid->rfc822($self->email()));
 
 my $ra=$self->auth();
 push @errs,'auth' if ($ra && (ref($ra) eq 'HASH') && exists($ra->{pw}) && !Net::DRI::Util::xml_is_normalizedstring($ra->{pw}));
 
 ## Nothing checked for disclose

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

1;
