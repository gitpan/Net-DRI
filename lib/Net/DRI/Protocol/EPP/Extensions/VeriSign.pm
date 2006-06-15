## Domain Registry Interface, VeriSign EPP extensions
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
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::VeriSign;

use strict;

use base qw/Net::DRI::Protocol::EPP/;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::VeriSign - VeriSign EPP extensions for Net::DRI

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
sub new
{
 my $h=shift;
 my $c=ref($h) || $h;

 my ($drd,$version,$extrah,$defproduct)=@_;
 my %e=map { $_ => 1 } (defined($extrah)? (ref($extrah)? @$extrah : ($extrah)) : ());

 $e{'Net::DRI::Protocol::EPP::Extensions::VeriSign::NameStore'}=1;
 $e{'Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync'}=1;
 ## We do no load automatically IDNLanguage & WhoisInfo as we do not know if they are mandatory
 ## NameStore seems mandatory, and Sync is just another operation, hence optional in all cases
 if (exists($e{':full'})) ## useful shortcut, modeled after Perl itself
 {
  delete($e{':full'});
  $e{'Net::DRI::Protocol::EPP::Extensions::VeriSign::IDNLanguage'}=1;
  $e{'Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoisInfo'}=1;
 }

 my $self=$c->SUPER::new($drd,$version,[keys(%e)]); ## we are now officially a Net::DRI::Protocol::EPP object
 $self->default_parameters()->{subproductid}=$defproduct || '_auto_';

 bless($self,$c); ## rebless
 return $self;
}

####################################################################################################
1;
