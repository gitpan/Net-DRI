#!/usr/bin/perl -w

use strict;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) 
{
 my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
 plan( skip_all => $msg );
}

#eval { use Test::Perl::Critic -exclude => ['ProhibitStringyEval']; };
eval { use Test::Perl::Critic; };

if ($@) 
{
 my $msg='Test::Perl::Critic required to criticise code';
 plan( skip_all => $msg );
}

all_critic_ok();
