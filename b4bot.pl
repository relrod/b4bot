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
    $result = $days.' days ';
  }
  if ($hours != 0) {
    $result .= $hours.' hours ';
  }
  $result .= $min.' minutes';
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

    when (/^${comchar}meep/) {
      return 'meep';
    }

    when (/^${comchar}sysinfo/) {
      my $hostname = `hostname -f`;
      my $kernel = `uname -r`;
      chomp($hostname);
      chomp($kernel);
      return 'The host I run on ('.$hostname.') has an uptime of: '.uptime().
        ' and uses kernel: '.$kernel;
    }

    when (/^${comchar}fortune/) {
      my $fortune = `fortune -s`;
      if (!$fortune) {
        return 'Could not retrieve your fortune. You will die.';
      } else {
        chomp($fortune);
        return $fortune;
      }
    }

    when (/^${comchar}longfortune/) {
      my $fortune = `fortune -l`;
      if (!$fortune) {
        return 'Could not retrieve a long fortune for you. You will die.';
      } else {
        chomp($fortune);
        return $fortune;
      }
    }

    when (/^${comchar}calc (.*)/) {
      my $calculator = WWW::Google::Calculator->new;
      return $calculator->calc($1);
    }
    
    when (/^${comchar}say (.*)/) {
      return $1;
    }

    when (/^${comchar}aspell(fr|is|ru|gb)? (.*)/) {
      my $speller = Text::Aspell->new;
      my $word_to_check = $2;
      if ($1) {
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
      if (!$output) {
        return 'No suggestions were found for: '.$word_to_check;
      }
      my $size = scalar @suggestions;
      return $size.' suggestion(s) for '.$word_to_check.': '.$output;
    }

    when (/^${comchar}lcalc (.+) (.+)/) {
      if ($1 == '0') {
        return 'First argument cannot be 0.';
      }
      my $lovematch = lovematch($1, $2);
      return 'Lovematch for '.$1.' and '.$2.': '.$lovematch.'%';
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
      my $wx = $weather->get_weather();
      if ($wx) {
        $wx = $wx->[0];
        return 'Weather for '.$wx->{'place'}.': '.$wx->{'conditions'}.'. '.
          'Temperature: '.$wx->{'temperature_fahrenheit'}.'F, or '.
          $wx->{'temperature_celsius'}.'C. Wind is '.$wx->{'wind_direction'}.
          ' at '.$wx->{'wind_milesperhour'}.' MPH.';
      } else {
        return 'FFFUUUUUUUUUU - Dat didn\'t work! The location probably'.
          ' could not be found.';
      }
    }

    # These are administrative commands. Eventually is_admin will check against the db.
    when (/^${comchar}join (.+)/) {
      if (is_admin($message->{'raw_nick'})) {
        $self->join($1);
      }
    }

    when (/^${comchar}topic (.+)/) {
      if (is_admin($message->{'raw_nick'})) {
        $self->privmsg('ChanServ', 'topic '.$message->{'channel'}.' '.$1);
      }
    }

    when (/^${comchar}kick (.+) ?(.+)?/) {
      if (is_admin($message->{'raw_nick'})) {
        if (!defined($2)) {
          $self->privmsg('ChanServ', 'op '.$message->{'channel'});
          $self->kick($message->{'channel'}, $1);
        } else { 
          $self->privmsg('ChanServ', 'op '.$message->{'channel'});
          $self->kick($message->{'channel'}, $1.' '.$2);
        }
      }
    }

    when (/^${comchar}op ?(.+)?/) {
      if (is_admin($message->{'raw_nick'})) {
        if (!defined($1)) {
          $self->privmsg('ChanServ', 'op '.$message->{'channel'}.' '.$message->{'who'});
        } else {
          $self->privmsg('ChanServ', 'op '.$message->{'channel'}.' '.$1);
        }
      }
    }

    when (/^${comchar}deop ?(.+)?/) {
      if (is_admin($message->{'raw_nick'})) {
        if (!defined($1)) {
          $self->privmsg('ChanServ', 'deop '.$message->{'channel'}.' '.$message->{'who'});
        } else {
          $self->privmsg('ChanServ', 'deop '.$message->{'channel'}.' '.$1);
        }
      }
    }

    when (/^${comchar}ban (.+)/) {
      if (is_admin($message->{'raw_nick'})) {
        $self->ban($message->{'channel'}, $1);
      }
    }

    when (/^${comchar}unban (.+)/) {
      if (is_admin($message->{'raw_nick'})) {
        $self->privmsg('ChanServ', 'akick del '.$message->{'channel'}.' '.$1);
      }
    }

    when (/${comchar}aquote (.+)/) {
      my $query = $dbh->prepare(
        'INSERT INTO quotes(meaning, quoter_nick, channel) VALUES(?, ?, ?)');
      my $result = $query->execute(
        $1,
        $message->{'who'},
        $message->{'channel'});
      if ($result) {
        my $qid = $dbh->last_insert_id(undef, undef, 'quotes', undef);
        return 'Successfully added Quote '.$qid.', by '.$message->{'who'}.
          ', to the QDB.';
      } else {
        return 'An error has occurred while trying to add '.$message->{'who'}.
          '\'s quote.';
      }
    }

    when (/${comchar}fquote (\d+)/) {
      my $quote = $dbh->selectrow_hashref(
        'SELECT id, meaning FROM quotes WHERE id=?',
        undef,
        $1);
      if ($quote) {
        return '['.$quote->{'id'}.'] '.$quote->{'meaning'};
      } else {
        return 'Could not fetch quote '.$1.' from the QDB';
      }
    }

    
    when (/${comchar}iquote (\d+)/) {
      my $quote = $dbh->selectrow_hashref(
        'SELECT * FROM quotes WHERE id=?',
        undef,
        $1);

      # Checking channel here because it is guaranteed to be there for all
      # new quotes. If it there, the quote is in the new style/schema.
      if ($quote && $quote->{'channel'}) {
        return 'Quote '.$quote->{'id'}.' was added on '.
          $quote->{'date_created'}.' in '.$quote->{'channel'}.' by '.
          $quote->{'quoter_nick'}.'.';
      } else {
        return 'Could not fetch info about quote '.$1.'.';
      }
    }

    when (/${comchar}rquote/) {
      my $quote = $dbh->selectrow_hashref(
        'SELECT id, meaning FROM quotes ORDER BY RAND() LIMIT 1');
      if ($quote) {
        return '['.$quote->{'id'}.'] '.$quote->{'meaning'};
      } else {
        return 'An error has occurred, but this should never happen.';
      }
    }

    when (/${comchar}(?:whatis|whatare) (.+)/) {
      my $fact = $dbh->selectrow_hashref(
        'SELECT name, meaning, action from factoids where name=? order by'.
          ' id desc limit 1',
        undef,
        $1);
      if ($fact) {
        if ($fact->{'action'}) {
          return chr(1).'ACTION '.$fact->{'meaning'}.chr(1);
        } else {
          return $fact->{'name'}.' is '.$fact->{'meaning'};
        }
      }
    }
    
  }
}

sub help { "I'm annoying, and I hunger for more deep-fried Chinamen." }

my @bots = ();
foreach my $bot (@{$config->{'bots'}}) {
  my $bot_obj = MyBot->new(
    nick => $bot->{'nick'},
    server => $bot->{'server'},
    channels => $bot->{'channels'},
    no_run => 1,
  );
  push(@bots, $bot_obj);
}

print <<ASCIIART;
 ########  ##        ########   #######  ########
 ##     ## ##    ##  ##     ## ##     ##    ##
 ##     ## ##    ##  ##     ## ##     ##    ##
 ########  ##    ##  ########  ##     ##    ##
 ##     ## ######### ##     ## ##     ##    ##
 ##     ##       ##  ##     ## ##     ##    ##
 ########        ##  ########   #######     ##
ASCIIART

print "Version 8.0.1\n";
print "Written by b4, <b4\@gewt.net> and CodeBlock <ricky\@elrod.me>\n";
print "http://www.github.com/codeblock/b4bot/\n";
foreach my $bot (@bots) {
  $bot->run();
}
use POE;
$poe_kernel->run();

