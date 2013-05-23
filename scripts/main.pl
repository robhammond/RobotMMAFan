#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

use Data::Dumper;
use JSON;
use LWP::Simple;
use Net::Twitter;
use FindBin qw($Bin);
use Proc::Daemon;
use Log::Log4perl;
use Config::Simple;
use File::Spec;

my %config = ();
Config::Simple->import_from("$Bin/../etc/robotmmafan.ini", \%config);
Proc::Daemon::Init;

Log::Log4perl::init_and_watch("$Bin/../etc/log4perl.conf",10);
my $logger = Log::Log4perl->get_logger("MAIN");

binmode STDOUT, ':utf8';

my $nt = Net::Twitter->new(
  traits   => [qw/API::RESTv1_1/],

  consumer_key        => $config{'twitter.consumer_key'},
  consumer_secret     => $config{'twitter.consumer_secret'},
  access_token        => $config{'twitter.access_token'},
  access_token_secret => $config{'twitter.access_token_secret'},
);

my $URL = 'http://api.twitter.com/1/lists/statuses.json?slug=fighters&owner_screen_name=ufc';
my $latest_id = undef;
my @bad_words = ();

my %bad_words = build_multilingual_bad_words_map("$Bin/../data/");

eval {
	#FIXME
	#$nt->update("\@earino father I have come online with many bad words.");
};

if ($@) {
	$logger->info("restarted with same bad words.");
}

my $tweet_count = 0;
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
    $tweet_count++;
    $latest_id = $tweet->{id};
    $logger->debug(Dumper($tweet));

    next unless defined($bad_words{$tweet->{lang}});

    foreach my $bad_word (@{$bad_words{$tweet->{lang}}}) {

      if ($tweet->{text} =~ qr/\b\Q$bad_word\E\b/i) {
	my $o_content = "\"@".$tweet->{user}->{screen_name}." ".$tweet->{text}."\"";
	$content = substr($o_content, 0, 140);

	$logger->info("MATCHED: |$bad_word|");
	$logger->info("Retweeting: $content was $o_content ");
        my $result = $nt->update($content);
	print "Result: ".Dumper($result)."\n";
	last;
      }
    }
  }
  $logger->info("parsed $tweet_count tweets");
  sleep(60);
}

sub build_multilingual_bad_words_map {
	my ($directory) = @_;

	my %bad_words = ( );
	foreach my $file (glob("$directory/*")) {
		open(INFILE, "<", $file)
			or die "Unable to open file, reason: $!\n";

		my ($volume,$directories,$file) = File::Spec->splitpath( $file );
		my ($language, $junk) = split(/\./, $file, 2);
		$bad_words{$language} = [];

		while (<INFILE>) {
			chomp;
			push($bad_words{$language}, $_);
		}
		
	}

	return %bad_words;
}
