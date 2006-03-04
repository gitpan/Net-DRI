## Domain Registry Interface, EPP Message
##
## Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Message;

use strict;

use XML::LibXML ();
use Encode ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg errlang command command_body cltrid svtrid queue_count queue_headid message_qdate message_content message_lang node_resdata node_extension result_greeting result_extra_info));

our $VERSION=do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Message - EPP Message for Net::DRI

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

Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut



########################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my $trid=shift;

 my $self={
           errcode => 2999,
          };

 bless($self,$class);

 $self->cltrid($trid) if (defined($trid) && $trid);
 return $self;
}

sub ns
{
 my ($self,$what)=@_;
 return $self->{ns} unless defined($what);

 if (ref($what) eq 'HASH')
 {
  $self->{ns}=$what;
  return $what;
 }
 return $self->{ns}->{$what}->[0] if exists($self->{ns}->{$what});
 return;
}

sub is_success { return (shift->errcode()=~m/^1/)? 1 : 0; } ## 1XXX is for success, 2XXX for failures

sub result_status
{
 my $self=shift;
 my $code=$self->errcode();
 return Net::DRI::Protocol::ResultStatus->new('epp',$self->errcode(),undef,$self->is_success(),$self->errmsg(),$self->errlang(),$self->result_extra_info());
}

sub command_extension_register
{
 my ($self,$ocmd,$ons)=@_;

 $self->{extension}=[] unless exists($self->{extension});
 my $eid=1+$#{$self->{extension}};
 $self->{extension}->[$eid]=[$ocmd,$ons,[]];
 return $eid;
}

sub command_extension
{
 my ($self,$eid,$rdata)=@_;

 if (defined($eid) && ($eid >= 0) && ($eid <= $#{$self->{extension}}) && defined($rdata) && (ref($rdata) eq 'ARRAY') && @$rdata)
 {
  $self->{extension}->[$eid]->[2]=[ @{$self->{extension}->[$eid]->[2]}, @$rdata ];
 } else
 {
  return $self->{extension};
 }
}

sub as_string
{
 my ($self,$to)=@_;
 my $rns=$self->ns();
 my $topns=$rns->{_main};
 my $ens=sprintf('xmlns="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$topns->[0],$topns->[0],$topns->[1]);
 my @d;
 push @d,'<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
 push @d,'<epp '.$ens.'>';
 my ($cmd,$ocmd,$ons)=@{$self->command()};
 my $nocommand=(!ref($cmd) && ($cmd eq 'hello'));
 push @d,'<command>' unless $nocommand;
 my $attr;
 if (ref($cmd))
 {
  ($cmd,$attr)=($cmd->[0],' '.join(' ',map { $_.'="'.$cmd->[1]->{$_}.'"' } keys(%{$cmd->[1]})));
 } else
 {
  $attr='';
 }

 my $body=$self->command_body();
 if (defined($ocmd) && $ocmd)
 {
  push @d,"<${cmd}${attr}>";
  push @d,"<${ocmd} ${ons}>";
  push @d,_toxml($body);
  push @d,"</${ocmd}>";
  push @d,"</${cmd}>";
 } else
 {
  if (defined($body) && $body)
  {
   push @d,"<${cmd}${attr}>";
   push @d,_toxml($body);
   push @d,"</${cmd}>";
  } else
  {
   push @d,"<${cmd}${attr}/>";
  }
 }
 
 ## OPTIONAL extension
 my $ext=$self->{extension};
 if (defined($ext) && (ref($ext) eq 'ARRAY') && @$ext)
 {
  push @d,'<extension>';
  foreach my $e (@$ext)
  {
   my ($ecmd,$ens,$rdata)=@$e;
   push @d,"<${ecmd} ${ens}>";
   push @d,_toxml($rdata);
   push @d,"</${ecmd}>";
  }
  push @d,'</extension>';
 }

 ## OPTIONAL clTRID
 my $cltrid=$self->cltrid();
 push @d,"<clTRID>${cltrid}</clTRID>" if (defined($cltrid) && $cltrid && Net::DRI::Util::xml_is_token($cltrid,3,64) && !$nocommand);
 push @d,'</command>' unless $nocommand;
 push @d,'</epp>';

 my $m=Encode::encode('utf8',join('',@d));
 my $l=pack('N',4+length($m)); ## RFC 3734 §4
 return (defined($to) && ($to eq 'tcp'))? $l.$m : $m;
}

sub _toxml
{
 my $rd=shift;
 my @t;
 foreach my $d ((ref($rd->[0]))? @$rd : ($rd)) ## $d is a node=ref array
 {
  my @c; ## list of children nodes
  my %attr;
  foreach my $e (grep { defined } @$d)
  {
   if (ref($e) eq 'HASH')
   {
    while(my ($k,$v)=each(%$e)) { $attr{$k}=$v; }
   } else
   {
    push @c,$e;
   }
  }
  my $tag=shift(@c);
  my $attr=keys(%attr)? ' '.join(' ',map { $_.'="'.$attr{$_}.'"' } sort(keys(%attr))) : '';
  if (!@c || (@c==1 && !ref($c[0]) && ($c[0] eq '')))
  {
   push @t,"<${tag}${attr}/>";
  } else
  {
   push @t,"<${tag}${attr}>";
   push @t,(@c==1 && !ref($c[0]))? xml_escape($c[0]) : _toxml(\@c);
   push @t,"</${tag}>";
  }
 }
 return @t;
}

sub xml_escape
{
 my $in=shift;
 $in=~s/&/&amp;/g;
 $in=~s/</&lt;/g;
 $in=~s/>/&gt;/g;
 return $in;
}

sub topns { return shift->ns->{_main}->[0]; }

sub get_content
{
 my ($self,$nodename,$ns,$ext)=@_;
 return unless (defined($nodename) && $nodename);

 my @tmp;
 my $n1=$self->node_resdata();
 my $n2=$self->node_extension();

 $ns||=$self->topns();

 if ($ext)
 {
  @tmp=$n2->getElementsByTagNameNS($ns,$nodename) if (defined($n2));
 } else
 {
  @tmp=$n1->getElementsByTagNameNS($ns,$nodename) if (defined($n1));
 }

 return unless @tmp;
 return wantarray()? @tmp : $tmp[0];
}

sub parse
{
 my ($self,$dc)=@_; ## DataRaw

 my $NS=$self->topns();
 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dc->as_string());
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/EPP',1,'Unsuccessfull parse, root element is not epp') unless ($root->getName() eq 'epp');

 if ($root->getElementsByTagNameNS($NS,'greeting'))
 {
  $self->errcode(1000); ## fake an OK
  my $r=$self->parse_greeting(($root->getElementsByTagNameNS($NS,'greeting'))[0]);
  $self->result_greeting($r);
  return;
 }
 Net::DRI::Exception->die(0,'protocol/EPP',1,'Unsuccessfull parse, no response block') unless $root->getElementsByTagNameNS($NS,'response');
 my $res=($root->getElementsByTagNameNS($NS,'response'))[0];

 ## result block(s)
 my @results=$res->getElementsByTagNameNS($NS,'result'); ## one element if success, multiple elements if failure RFC3730 §2.6
 foreach (@results)
 {
  my ($errc,$errm,$errl)=$self->parse_result($_);
  ## TODO : store all in a stack (to preserve the list of results ?)
  $self->errcode($errc);
  $self->errmsg($errm);
  $self->errlang($errl);
 }

 ## TO FIX : in ServiceMessages ?
 if ($res->getElementsByTagNameNS($NS,'msgQ')) ## OPTIONAL
 {
  my $msgq=($res->getElementsByTagNameNS($NS,'msgQ'))[0];
  $self->queue_count($msgq->getAttribute('count'));
  $self->queue_headid($msgq->getAttribute('id'));
  ## if we have done a poll request, we may have childs
  if ($msgq->hasChildNodes())
  {
   $self->message_qdate(($msgq->getElementsByTagNameNS($NS,'qDate'))[0]->getData());
   my $msgc=($msgq->getElementsByTagNameNS($NS,'msg'))[0];
   $self->message_content($msgc->toString()); ## TO FIX
   $self->message_lang($msgc->getAttribute('lang') || 'en');
  }
 }

 if ($res->getElementsByTagNameNS($NS,'resData')) ## OPTIONAL
 {
  $self->node_resdata(($res->getElementsByTagNameNS($NS,'resData'))[0]);
 }

 if ($res->getElementsByTagNameNS($NS,'extension')) ## OPTIONAL
 {
  $self->node_extension(($res->getElementsByTagNameNS($NS,'extension'))[0]);
 }

 ## trID
 my $trid=($res->getElementsByTagNameNS($NS,'trID'))[0];
 $self->cltrid(($trid->getElementsByTagNameNS($NS,'clTRID'))[0]->firstChild->getData()) if $trid->getElementsByTagNameNS($NS,'clTRID');
 $self->svtrid(($trid->getElementsByTagNameNS($NS,'svTRID'))[0]->firstChild->getData()) if $trid->getElementsByTagNameNS($NS,'svTRID');
}

sub parse_result
{
 my ($self,$node)=@_;
 my $NS=$self->topns();
 my $code=$node->getAttribute('code');
 my $msg=($node->getElementsByTagNameNS($NS,'msg'))[0];
 my $lang=$msg->getAttribute('lang') || 'en';
 $msg=$msg->firstChild()->getData();

 my $c=$node->getFirstChild();
 while ($c)
 {
  my $name=$c->nodeName();
  next unless $name;
 
  if ($name eq 'extValue') ## OPTIONAL
  {
   push @{$self->{result_extra_info}},substr(substr($c->toString(),10),0,-11);
  } elsif ($name eq 'value') ## OPTIONAL
  {
   push @{$self->{result_extra_info}},$c->toString();
  }

  $c=$c->getNextSibling();
 }

 return ($code,$msg,$lang);
}

sub parse_greeting
{
 my ($self,$g)=@_;
 my %tmp;
 my $c=$g->getFirstChild();
 while($c)
 {
  my $n=$c->getName();
  if ($n=~m/^(svID|svDate)$/)
  {
   $tmp{$1}=$c->getFirstChild->getData();
  } elsif ($n eq 'svcMenu')
  {
   my $cc=$c->getFirstChild();
   while($cc)
   {
    my $nn=$cc->getName();
    if ($nn=~m/^(version|lang)$/)
    {
     push @{$tmp{$1}},$cc->getFirstChild->getData();
    } elsif ($nn eq 'objURI')
    {
     push @{$tmp{svcs}},$cc->getFirstChild->getData();
    } elsif ($nn eq 'svcExtension')
    {
     push @{$tmp{svcext}},map { $_->getFirstChild->getData() } grep { $_->getName() eq 'extURI' } $cc->getChildNodes();
    }
    $cc=$cc->getNextSibling();
   }
  } elsif ($n eq 'dcp')
  {
   ## TODO : do something with that data
  }
  $c=$c->getNextSibling();
 }

 return \%tmp;
}

########################################################################

sub get_name_from_message
{
 my ($self)=@_;
 my $cb=$self->command_body();
 return 'session' unless (defined($cb) && ref($cb)); ## TO FIX
 foreach my $e (@$cb)
 {
  return $e->[1] if ($e->[0]=~m/^(?:domain|host|nsgroup):name$/); ## TO FIX (notably in case of check_multi)
  return $e->[1] if ($e->[0]=~m/^contact:id$/); ## TO FIX
 }
 return 'session'; ## TO FIX
}

########################################################################
1;
