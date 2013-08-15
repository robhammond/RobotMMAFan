#!/usr/bin/env perl
#
use warnings;
use strict;

my @words = qw/ homo fag bitch /;

{
	print "Input: ";
	my $input = <>;
	foreach my $word (@words) {
		my $re = qr/\b$word\b/i;
		print "MATCHES $word\n" if $input =~ $re;
	}

	redo;
}
