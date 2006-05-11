## Domain Registry Interface, AFNIC Email Domain commands
##
## Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::AFNIC::Email::Domain;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::AFNIC::Email::Domain - AFNIC Email Domain commands for Net::DRI

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

Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          create => [ \&create, undef ], ## TODO : parsing of return messages
         );

 return { 'domain' => \%tmp };
}

sub verify_rd
{
 my ($rd,$key)=@_;
 return 0 unless (defined($key) && $key);
 return 0 unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{$key}) && defined($rd->{$key}));
 return 1;
}

sub format_tel
{
 my $in=shift;
 $in=~s/x.*$//;
 $in=~s/\./ /;
 return $in;
}

sub create
{
 my ($a,$domain,$rd)=@_;
 my $mes=$a->message();
 my $ca=$mes->client_auth();

 $mes->line('1a','C');
 $mes->line('1b',$ca->{id}); ## code fournisseur
 $mes->line('1c',$ca->{pw}); ## mot de passe
 $mes->line('1e',$mes->trid()); ## reference client (=trid) ## allow more/other ?
 $mes->line('1f','2.0.0');
 $mes->line('1g',$rd->{auth_reserved}) if (verify_rd($rd,'auth_reserved') && $rd->{auth_reserved}); ## authorization code for reserved domain names

 $mes->line('2a',$domain);
 
 Net::DRI::Exception::usererr_insufficient_parameters("contacts are mandatory") unless (verify_rd($rd,'contact') && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet'));
 my $cs=$rd->{contact};
 my $co=$cs->get('registrant');
 Net::DRI::Exception::usererr_insufficient_parameters("registrant contact is mandatory") unless ($co && UNIVERSAL::isa($co,'Net::DRI::Data::Contact::AFNIC'));
 $co->validate();
 $co->validate_is_french() unless ($co->roid()); ## registrant must be in France

 if ($co->org()) ## PM
 {
  $mes->line('3w','PM');
  $mes->line('3a',$co->org());
  Net::DRI::Exception::usererr_insufficient_parameters("one legal form must be provided") unless ($co->legal_form() || $co->legal_form_other());
  $mes->line('3h',$co->legal_form())       if $co->legal_form();
  $mes->line('3i',$co->legal_form_other()) if $co->legal_form_other();
  Net::DRI::Exception::usererr_insufficient_parameters("legal id must be provided if no trademark") if (($co->legal_form() eq 'S') && !$co->trademark() && !$co->legal_id());
  $mes->line('3j',$co->legal_id())         if $co->legal_id();
  my $jo=$co->jo();
  Net::DRI::Exception::usererr_insufficient_parameters("jo data is needed for non profit organization without legal id or trademark") if (($co->legal_form() eq 'A') && !$co->legal_id() && !$co->trademark() && (!$jo || (ref($jo) ne 'HASH') || !exists($jo->{date_publication}) || !exists($jo->{page})));
  if ($jo && (ref($jo) eq 'HASH'))
  {
   $mes->line('3k',$jo->{date_declaration}) if (exists($jo->{date_declaration}) && $jo->{date_declaration});
   $mes->line('3l',$jo->{date_publication}) if (exists($jo->{date_publication}) && $jo->{date_publication});
   $mes->line('3m',$jo->{number})           if (exists($jo->{number})           && $jo->{number});
   $mes->line('3n',$jo->{page})             if (exists($jo->{page})             && $jo->{page});
  }
  $mes->line('3p',$co->trademark()) if $co->trademark();
 } else ## PP
 {
  $mes->line('3w','PP');
  Net::DRI::Exception::usererr_insufficient_parameters("name or key needed for PP") unless ($co->name() || $co->key());
  if ($co->key())
  {
   $mes->line('3q',$co->key());
  } else
  {
   $mes->line('3a',$co->name());
   my $b=$co->birth();
   Net::DRI::Exception::usererr_insufficient_parameters("birth data mandatory, if no registrant key provided") unless ($b && (ref($b) eq 'HASH') && exists($b->{date}) && exists($b->{place}));
   $mes->line('3r',$b->{date});
   $mes->line('3s',$b->{place});
  }
 }

 if ($co->org() || !$co->roid())
 {
  my $s=$co->street();
  Net::DRI::Exception::usererr_insufficient_parameters("1 line of address at least needed if no nichandle") unless ($s && (ref($s) eq 'ARRAY') && @$s && $s->[0]);
  $mes->line('3b',$s->[0]);
  $mes->line('3c',$s->[1]) if $s->[1];
  $mes->line('3d',$s->[2]) if $s->[2];
  Net::DRI::Exception::usererr_insufficient_parameters("city, pc & cc mandatory if no nichandle") unless ($co->city() && $co->pc() && $co->cc());
  $mes->line('3e',$co->city());
  $mes->line('3f',$co->pc());
  $mes->line('3g',uc($co->cc()));
  Net::DRI::Exception::usererr_insufficient_parameters("voice & email mandatory if no nichandle") unless ($co->voice() && $co->email());
  $mes->line('3t',format_tel($co->voice()));
  $mes->line('3u',format_tel($co->fax())) if $co->fax();
  $mes->line('3v',$co->email());
  Net::DRI::Exception::usererr_insufficient_parameters("maintainer mandatory if no nichandle") unless (verify_rd($rd,'maintainer') && $rd->{maintainer}=~m/^[A-Z0-9][-A-Z0-9]+[A-Z0-9]$/i);
  $mes->line('3y',$rd->{maintainer});
  Net::DRI::Exception::usererr_insufficient_parameters("disclose option is mandatory if no nichandle") unless ($co->disclose());
  $mes->line('3z',$co->disclose());
 } else
 {
  $mes->line('3x',$co->roid());
 }

 $co=$cs->get('admin');
 $mes->line('4a',$co->roid()) if ($co && UNIVERSAL::isa($co,'Net::DRI::Data::Contact') && $co->roid());

 my @co=map { $_->roid() } grep { UNIVERSAL::isa($_,'Net::DRI::Data::Contact') } $cs->get('tech');
 Net::DRI::Exception::usererr_insufficient_parameters("at least one technical contact is mandatory") unless @co;
 $mes->line('5a',$co[0]);
 $mes->line('5c',$co[1]) if $co[1];
 $mes->line('5e',$co[2]) if $co[2];

 Net::DRI::Exception::usererr_insufficient_parameters("at least 2 nameservers are mandatory") unless (verify_rd($rd,'ns') && UNIVERSAL::isa($rd->{ns},'Net::DRI::Data::Hosts') && !$rd->{ns}->is_empty() && $rd->{ns}->count() >= 2);
 add_ns($mes,$rd->{ns},1,$domain,'6a','6b');
 add_ns($mes,$rd->{ns},2,$domain,'7a','7b');
 my $nsc=$rd->{ns}->count();
 add_ns($mes,$rd->{ns},3,$domain,'7c','7d') if ($nsc >= 3);
 add_ns($mes,$rd->{ns},4,$domain,'7e','7f') if ($nsc >= 4);
 add_ns($mes,$rd->{ns},5,$domain,'7g','7h') if ($nsc >= 5);
 add_ns($mes,$rd->{ns},6,$domain,'7i','7j') if ($nsc >= 6);
 add_ns($mes,$rd->{ns},7,$domain,'7k','7l') if ($nsc >= 7);
 add_ns($mes,$rd->{ns},8,$domain,'7m','7n') if ($nsc >= 8);

 ## Default = A = waiting for client, otherwise I = direct installation
 $mes->line('8a',$rd->{installation_type}) if (verify_rd($rd,'installation_type') && ($rd->{installation_type}=~m/^[IA]$/));
 ## S = standard = fax need to be sent, Default = E = Express = no fax
 $mes->line('9a',$rd->{form_type})         if (verify_rd($rd,'form_type')         && ($rd->{form_type}=~m/^[SE]$/));
}

sub add_ns
{
 my ($mes,$ns,$pos,$domain,$l1,$l2)=@_;
 my @g=$ns->get_details($pos);
 return unless @g;
 $mes->line($l1,$g[0]); ## name
 return unless ($g[0]=~m/\S+\.${domain}/i || (lc($g[0]) eq lc($domain)));
 $mes->line($l2,join(' ',@{$g[1]},@{$g[2]})); ## nameserver in domain, we add IPs
}

####################################################################################################
1;
