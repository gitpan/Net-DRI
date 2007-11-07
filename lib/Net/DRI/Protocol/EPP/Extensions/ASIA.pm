## Domain Registry Interface, ASIA EPP extensions
##
## Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ASIA;

use strict;

use Net::DRI::Data::Contact::ASIA;
use base qw/Net::DRI::Protocol::EPP/;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA - ASIA EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################
sub new
{
 my $h=shift;
 my $c=ref($h) || $h;

 my ($drd,$version,$extrah,$defproduct)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 if (exists($e{':full'})) ## useful shortcut, modeled after Perl itself
 {
  delete($e{':full'});
  $e{'Net::DRI::Protocol::EPP::Extensions::GracePeriod'}=1;
  $e{'Net::DRI::Protocol::EPP::Extensions::ASIA::IPR'}=1;
  $e{'Net::DRI::Protocol::EPP::Extensions::ASIA::CED'}=1;
 }

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]); ## we are now officially a Net::DRI::Protocol::EPP object

 if (exists($e{'Net::DRI::Protocol::EPP::Extensions::ASIA::CED'}))
 {
  my $rfact=$self->factories();
  $rfact->{contact}=sub { return Net::DRI::Data::Contact::ASIA->new(@_); };
 }

 bless($self,$c); ## rebless
 return $self;
}

####################################################################################################
1;
