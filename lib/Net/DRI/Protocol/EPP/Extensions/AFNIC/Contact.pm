## Domain Registry Interface, AFNIC (.FR/.RE) Contact EPP extension commands
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Contact - AFNIC (.FR/.RE) EPP Contact extensions for Net::DRI

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

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
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
          create  => [ \&create, \&create_parse ],
          update => [ \&update, undef ],
          info       => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:frnic="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('frnic')));
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

## validate() has been called
 my @n;
 if ($contact->org() && $contact->legal_form()) # PM
 {
  my @d;
  Net::DRI::Exception::usererr_insufficient_parameters('legal_form data mandatory') unless ($contact->legal_form());
  Net::DRI::Exception::usererr_invalid_parameters('legal_form_other data mandatory if legal_form=other') if (($contact->legal_form() eq 'other') && !$contact->legal_form_other());
  push @d,['frnic:status',{type => $contact->legal_form()},$contact->legal_form() eq 'other'? $contact->legal_form_other() : ''];
  push @d,['frnic:siren',$contact->legal_id()] if $contact->legal_id();
  push @d,['frnic:trademark',$contact->trademark()] if $contact->trademark();
  my $jo=$contact->jo();
  if (defined($jo) && (ref($jo) eq 'HASH'))
  {
   my @j;
   push @j,['frnic:decl',$jo->{date_declaration}];
   push @j,['frnic:publ',{announce=>$jo->{number},page=>$jo->{page}},$jo->{date_publication}];
   push @d,['frnic:asso',@j];
  }
  push @n,['frnic:legalEntityInfos',@d];
 } else # PP
 {
  ## This is a big kludge ! TODO ->name()=prenom\s*,\*nom but we will have to change Core contact:name !
  my $body=$mes->command_body();
  my (@name)=($body->[1]->[1]->[1]=~m/^\s*(\S.*\S)\s*,\s*(\S.*\S)\s*$/); ## contact:id then contact:postalInfo and inside contact:name
  $body->[1]->[1]->[1]=$name[1];
  push @n,['frnic:surname',$name[0]];
  push @n,['frnic:list','restrictedPublication'] if ($contact->disclose() eq 'N');
  my @d;
  my $b=$contact->birth();
  Net::DRI::Exception::usererr_insufficient_parameters('birth data mandatory') unless ($b && (ref($b) eq 'HASH') && exists($b->{date}) && exists($b->{place}));
  push @d,['frnic:birthdate',(ref($b->{date}))? $b->{date}->strftime('%Y-%m-%d') : $b->{date}];
  if ($b->{place}=~m/^[A-Z]{2}$/i) ## country not France
  {
   push @d,['frnic:cc',$b->{place}];
  } else
  {
   my @p=($b->{place}=~m/^\s*(\S.*\S)\s*,\s*(\S.+\S)\s*$/);
   push @d,['frnic:birthcity',$p[1]];
   push @d,['frnic:pc',$p[0]];
   push @d,['frnic:cc','FR'];
  }
  push @n,['frnic:individualInfos',@d];
 }

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:create',['frnic:contact',@n]]);
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_extension('frnic','ext');
 return unless $credata;
 my $ns=$mes->ns('frnic');
 my $c=$credata->getChildrenByTagNameNS($ns,'resData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'creData');
 return unless $c->size();

 $oname=$rinfo->{contact}->{$oname}->{id}; ## take into account true ID (the one returned by the registry)
 $c=$c->shift()->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'nhStatus')
  {
   $rinfo->{contact}->{$oname}->{new_handle}=$c->getAttribute('new');
  } elsif ($name eq 'idStatus')
  {
   $rinfo->{contact}->{$oname}->{identification}=$c->getFirstChild()->getData();
  }
 } continue { $c=$c->getNextSibling(); }
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $dadd=$todo->add('disclose');
 my $ddel=$todo->del('disclose');
 return unless ($dadd || $ddel);

 my @n;
 push @n,['frnic:add',['frnic:list',$dadd]] if $dadd;
 push @n,['frnic:rem',['frnic:list',$ddel]] if $ddel;
 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:update',['frnic:contact',@n]]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('frnic','ext');
 return unless $infdata;
 my $ns=$mes->ns('frnic');
 my $c=$infdata->getChildrenByTagNameNS($ns,'resData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'infData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'contact');
 return unless $c->size();

 my $co=$rinfo->{contact}->{$oname}->{self};
 $c=$c->shift()->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'surname')
  {
   $co->name(sprintf('%s, %s',$c->getFirstChild()->getData(),$co->name()));
  } elsif ($name eq 'list')
  {
   my $v=$c->getFirstChild()->getData();
   $co->disclose($v eq 'restrictedPublication'? 'N' : 'Y');
  } elsif ($name eq 'individualInfos')
  {
    my $cc=$c->getFirstChild();
    my %b;
    while($cc)
    {
      next unless ($cc->nodeType() == 1);
      my $nn=$cc->localname() || $c->nodeName();
      next unless $nn;

      if ($nn eq 'idStatus')
      {
        $rinfo->{contact}->{$oname}->{identification}=$cc->getFirstChild()->getData();
      } elsif ($nn eq 'birthdate')
      {
        $b{date}=$cc->getFirstChild()->getData();
      } elsif ($nn eq 'birthcity')
      {
        $b{place}=$cc->getFirstChild()->getData();
      } elsif ($nn eq 'pc')
      {
       $b{place}=sprintf('%s, %s',$cc->getFirstChild()->getData(),$b{place});
      } elsif ($nn eq 'cc')
      {
       my $v=$cc->getFirstChild()->getData();
       $b{place}=$v unless ($v eq 'FR');
      }
    } continue { $cc=$cc->getNextSibling(); }
    $co->birth(\%b);
  } elsif ($name eq 'legalEntityInfos')
  {
    my $cc=$c->getFirstChild();
    while($cc)
    {
      next unless ($cc->nodeType() == 1);
      my $nn=$cc->localname() || $c->nodeName();
      next unless $nn;

      if ($nn eq 'status')
      {
       $co->legal_form($cc->getAttribute('type'));
       my $v=$cc->getFirstChild()->getData();
       $co->legal_form_other($v) if $v;
      } elsif ($nn eq 'siren')
      {
       $co->legal_id($cc->getFirstChild()->getData());
      } elsif ($nn eq 'trademark')
      {
       $co->trademark($cc->getFirstChild()->getData());
      } elsif ($nn eq 'asso')
      {
        my %jo;
        my $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'decl');
        $jo{date_declaration}=$ccc->shift()->getFirstChild()->getData() if ($ccc->size());
        $ccc=$cc->getChildrenByTagNameNS($mes->ns('frnic'),'publ');
        if ($ccc->size())
        {
          my $p=$ccc->shift();
          $jo{number}=$p->getAttribute('announce');
          $jo{page}=$p->getAttribute('page');
          $jo{date_publication}=$p->getFirstChild()->getData();
        }
        $co->jo(\%jo);
      }
    } continue { $cc=$cc->getNextSibling(); }
  }
 } continue { $c=$c->getNextSibling(); }
}

####################################################################################################
1;
