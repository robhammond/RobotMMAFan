#!/usr/bin/env perl
#
use warnings;
use strict;

use FindBin qw($Bin);

open(DICT, "<", "/usr/share/dict/words")
	or die "Unable to open dict.";

open(SLURS, "<", "$Bin/../data/slurs.txt")
	or die "Unable to open slurs.";

my %dict = ();
while (<DICT>) {
	chomp;
	$dict{uc $_}++;
}

while (<SLURS>) {
	chomp;
	next if $dict{uc $_};
	print "$_\n";
}
