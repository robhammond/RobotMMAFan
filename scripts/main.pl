#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

use Data::Dumper;
use JSON;
use LWP::Simple;
use Net::Twitter;

binmode STDOUT, ':utf8';

my $nt = Net::Twitter->new(
  traits   => [qw/API::RESTv1_1/],

  consumer_key        => 'TKRSM4XCISiSBUoxAHUDIA',
  consumer_secret     => 'Gb8jVLOnDePTaXo2GxLHAO1vrYurGn2If9qUpaGaSeI',
  access_token        => '1433851416-JWqqXsP68wRFpM6yP0h6puISlpDZq3ds9zpqfYU',
  access_token_secret => 'eJMmDNRMzWsDmZcTcVCk4efAdndzqyIsugTEoTRh0',
);

my $URL = 'http://api.twitter.com/1/lists/statuses.json?slug=fighters&owner_screen_name=ufc';
my $latest_id = undef;
my @bad_words = qw/
  fag faggot fagget homo gay queer tranny rape
  cunt lesbian lesbo nigger whore motherfucker
  cocksucker twat retard fucktard paki
/;

while (1) {
  my $current_url = $URL;
  if ($latest_id) {
    $current_url .= "&since_id=$latest_id";
  }
  my $content;

  {
	$content = get($current_url);
	sleep 60 and redo unless defined $content;
  }
  my $data = decode_json($content);

  foreach my $tweet (reverse @{$data}) {
    $latest_id = $tweet->{id};
    foreach my $bad_word (@bad_words) {
      if ($tweet->{text} =~ qr/\b$bad_word\b/i) {
	my $o_content = "\"@".$tweet->{user}->{screen_name}." ".$tweet->{text}."\"";
	$content = substr($o_content, 0, 140);

	print "Matched: $bad_word\n";
	print "Retweeting: $content was $o_content ";
        my $result = $nt->update($content);
	print "Result: ".Dumper($result)."\n";
      }
    }
  }
  sleep(60);
}
