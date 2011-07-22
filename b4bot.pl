#!/usr/bin/perl -w

use strict;

package MyBot;
use feature 'switch';
use base qw( Bot::BasicBot );
use LWP;
use URI;
use DBI;
use Weather::Underground;
use Text::Aspell;
use IMDB::Film;
use URI::Escape;
use WWW::Google::Calculator;
use Love::Match::Calc;
use YAML;

# TODO: Better handling if both of these fail.
my $config = YAML::LoadFile($ARGV[0] || 'config.yaml');
my $comchar = $config->{'comchar'};

my $dbh = DBI->connect(
  $config->{'database'}->{'dsn'},
  $config->{'database'}->{'username'},
  $config->{'database'}->{'password'});
$dbh->{mysql_auto_reconnect} = 1;

# CHANGEPROP: 'Custom.pm' module for this stuff?
sub uptime() {
  use POSIX qw(ceil floor);
  open UPTIME,'<','/proc/uptime' or print $!;
  my @lines = <UPTIME>;
  my $uptime = $lines[0];
  close UPTIME;
  my @sys_ticks_arr = split(/ /,$uptime);
  my $sys_ticks = $sys_ticks_arr[0];
  my $min = $sys_ticks / 60;
  my $hours = $min / 60;
  my $days = floor($hours / 24);
  $hours = floor($hours - ($days * 24));
  $min = floor($min - ($days * 60 * 24) - ($hours * 60));
  my $result;
  if ($days != 0) {
    $result = '$days days ';
  }
  if ($hours != 0) {
    $result .= '$hours hours ';
  }
  $result .= '$min minutes';
  return $result;
}

sub is_admin {
  my @admins = (
    'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net',
  );
  return grep(shift eq $_, @admins);
}

sub said {
  my ($self, $message) = @_;

  given ($message->{'body'}) {
    when (/^${comchar}whoami/) {
      return 'You are: '.$message->{'raw_nick'};
    }

    when (/^${comchar}say (.*)/) {
      $self->privmsg($message->{'channel'}, $1)
    }

    when (/^${comchar}aspell(fr|is|ru|gb)? (.*)/) {
      my $speller = Text::Aspell->new;
      my $word_to_check = $2;
      if ($1) {
        return '$1 IS '.$1.' !!!';
        given ($1) {
          when ('fr') { $speller->set_option('lang', 'fr_FR') }
          when ('is') { $speller->set_option('lang', 'is_IS') }
          when ('ru') { $speller->set_option('lang', 'ru_RU') }
          when ('cy') { $speller->set_option('lang', 'cy_GB') }
        }
      } else {
        $speller->set_option('lang', 'en_US');
      }
      my @suggestions = $speller->suggest($word_to_check);
      my $output .= join(", ", @suggestions);
      my $size = scalar @suggestions;
      return $size.' suggestion(s) for '.$word_to_check.': '.$output;
    }

    when (/^${comchar}ping/) {
      return "Pong"
    }

    when (/^${comchar}weather (.+)/) {
      my $weather = Weather::Underground->new(
        place => $1,
        debug => 0,
      );
      if (!$weather) {
        return 'Could not create weather object. ('.$1.')';
      }
      my $wx = $weather->get_weather()->[0];
      if ($wx) {
        return 'Weather for '.$wx->{'place'}.': '.$wx->{'conditions'}.'. '.
          'Temperature: '.$wx->{'temperature_fahrenheit'}.'F, or '.
          $wx->{'temperature_celsius'}.'C. Wind is '.$wx->{'wind_direction'}.
          ' at '.$wx->{'wind_milesperhour'}.' MPH.';
      } else {
        return 'FFFUUUUUUUUUU - Dat didn\'t work!';
      }
    }
  }
}

sub help { "I'm annoying, and I hunger for more deep-fried Chinamen." }

# CHANGEPROP: CONFIG FILE DAMNIT!
my $bot4 = MyBot->new(
  nick => "b4bot_codeblock",
  server => "irc.ninthbit.net",
  channels => ['#flood'],
  no_run => 1,
);

print
  " ########  ##        ########   #######  ########
 ##     ## ##    ##  ##     ## ##     ##    ##
 ##     ## ##    ##  ##     ## ##     ##    ##
 ########  ##    ##  ########  ##     ##    ##
 ##     ## ######### ##     ## ##     ##    ##
 ##     ##       ##  ##     ## ##     ##    ##
 ########        ##  ########   #######     ## \n";

  print "Version 7.54.2\n";
print "Codename: Disco Superfly\n";
print "Written by b4, <b4\@gewt.net>, Some stuff by CodeBlock\n";
print "This is b4bot 7.0-dev, A almost complete rewrite of b4bot.\n";
print "http://hg.gewt.net/b4bot -- Website coming soon?\n";
my @bots = ($bot4);
foreach my $bot (@bots) {
  $bot->run();
}
use POE;
$poe_kernel->run();

