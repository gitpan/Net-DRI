#!/usr/bin/perl

use strict;
use warnings;

require Test::Perl::Critic;

Test::Perl::Critic->import(-severity => 'gentle');
all_critic_ok();
