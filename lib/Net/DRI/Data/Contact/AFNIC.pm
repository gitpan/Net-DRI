## Domain Registry Interface, Handling of contact data for AFNIC
##
## Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::Contact::AFNIC;

use strict;
use encoding 'iso-8859-15';
use base qw/Net::DRI::Data::Contact/;
__PACKAGE__->mk_accessors(qw(legal_form legal_form_other legal_id jo trademark key birth));

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::Contact::AFNIC - Handle AFNIC contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
AFNIC specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 roid()

NIC handle for the contact

=head2 legal_form()

for an organization, either 'A' for non profit organization or 'S' for company

=head2 legal_form_other()

type of organization for other types

=head2 legal_id()

French SIREN/SIRET of organization

=head2 jo()

reference to an hash with 4 keys storing details about «Journal Officiel» :
date_declaration (Declaration date), date_publication (Publication date),
number (Announce number) and page (Announce page)

=head2 trademark()

for trademarks, its number

=head2 key()

registrant invariant key

=head2 birth()

reference to an hash with 2 keys storing details about birth of contact :
date (Date of birth) and place (Place of birth)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

our $LETTRES=qr{A-ZÀÂÇÈÉÊËÎÏÔÙÛÜ¾Æ¼a-zàâçèéêëîïôùûüÿæ½};
our $NOM_LIBRE_ITEM=qr{[${LETTRES}0-9\(\)\.\[\]\?\+\*#&/!\@',><":-]+};
our $NOM_PROPRE_ITEM=qr{[${LETTRES}]+(('?(?:[${LETTRES}]+(?:\-?[${LETTRES}]+)?)+)|(?:\.?))};
our $NOM_PROPRE=qr{${NOM_PROPRE_ITEM}( +${NOM_PROPRE_ITEM})*};
our $ADRESSE_ITEM=qr{[${LETTRES}0-9\(\)\./',"#-]+};

sub is_nom_libre { return shift=~m/^(?:${NOM_LIBRE_ITEM} *)*[${LETTRES}0-9]+(?: *${NOM_LIBRE_ITEM}*)*$/; }
sub is_adresse   { return shift=~m/^(?:${ADRESSE_ITEM} *)*[${LETTRES}]+(?: *${ADRESSE_ITEM})*$/; }
sub is_code_fr   { return shift=~m/^(?:FR|RE|MQ|GP|GF|TF|NC|PF|WF|PM|YT)$/; }

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

## NIC handle
 push @errs,'roid' if ($self->roid() && $self->roid()!~m/^[A-Z]+(?:[1-9][0-9]*)?-FRNIC$/i);

 push @errs,'name' if ($self->name() && $self->name()!~m/^${NOM_PROPRE} *, *${NOM_PROPRE}$/);
 push @errs,'org'  if ($self->org()  && ! is_nom_libre($self->org()));

 my $rs=$self->street();
 push @errs,'street' if ($rs && ((ref($rs) ne 'ARRAY') || (@$rs > 3) || (grep { ! is_adresse($_) } @$rs)));

 push @errs,'city' if ($self->city() && $self->city()!~m/^${NOM_PROPRE}$/);

 my $cc=$self->cc();
 my $isccfr=0;
 if ($cc)
 {
  push @errs,'cc' if !exists($Net::DRI::Util::CCA2{uc($cc)});
  $isccfr=is_code_fr(uc($cc));
 }
 my $pc=$self->pc();
 if ($pc)
 {
  if ($isccfr)
  {
   push @errs,'pc' unless $pc=~m/^[0-9]{5}$/;
  } else
  {
   push @errs,'pc' unless $pc=~m/^[-0-9A-Za-z]+$/;
  }
 }

 push @errs,'legal_form'       if ($self->legal_form()       && $self->legal_form()!~m/^[AS]$/);
 push @errs,'legal_form_other' if ($self->legal_form_other() && $self->legal_form_other()!~m/^${NOM_PROPRE}$/);
 push @errs,'legal_id'         if ($self->legal_id()         && $self->legal_id()!~m/^[0-9]{9}(?:[0-9]{5})?$/);

 my $jo=$self->jo();
 if ($jo)
 {
  if ((ref($jo) eq 'HASH') && exists($jo->{date_declaration}) && exists($jo->{date_publication}) && exists($jo->{number}) && exists ($jo->{page}))
  {
   push @errs,'jo' unless $jo->{date_declaration}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$!;
   push @errs,'jo' unless $jo->{date_publication}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$!;
   push @errs,'jo' unless $jo->{number}=~m/^[1-9][0-9]+$/;
   push @errs,'jo' unless $jo->{page}=~m/^[1-9][0-9]+$/;
  } else
  {
   push @errs,'jo';
  }
 }

 push @errs,'trademark' if ($self->trademark() && $self->trademark()!~m/^[0-9]*[A-Za-z]*[0-9]+$/);

 push @errs,'key' if ($self->key() && $self->key()!~m/^[A-Za-z]{8}-[1-9][0-9]{2}$/);

 my $birth=$self->birth();
 if ($birth)
 {
  if ((ref($birth) eq 'HASH') && exists($birth->{date}) && exists($birth->{place}))
  {
   push @errs,'birth' unless ((ref($birth->{date}) eq 'DateTime') || $birth->{date}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$!);
   push @errs,'birth' unless $birth->{place}=~m!^(?:[A-Za-z]{2}|[0-9]{2}(?:[0-9]{3})* *, *${NOM_PROPRE})$!;
  } else
  {
   push @errs,'birth';
  }
 }

 ## Not same checks as AFNIC, but we will translate to their format when needed, better to standardize on EPP
 if ($self->voice())
 {
  push @errs,'voice' if $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/;
  push @errs,'voice' if ($isccfr && $self->voice()!~m/^\+33\./);
 }
 if ($self->fax())
 {
  push @errs,'fax' if $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/;
  push @errs,'fax' if ($isccfr && $self->fax()!~m/^\+33\./);
 }
 push @errs,'email' if ($self->email() && !Email::Valid->rfc822($self->email()));

 ## No need to test type, we will set it up automatically when needed (organisation empty => PP, otherwise PM)
 ## Maintainer is not tied to contact
 
 push @errs,'disclose' if ($self->disclose() && $self->disclose()!~m/^[ONY]$/i);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

## Test for registrants
sub validate_is_french
{
 my $self=shift;
 Net::DRI::Exception::usererr_invalid_parameters('Registrant contact must be French') unless is_code_fr(uc($self->cc()));
}

####################################################################################################
1;
