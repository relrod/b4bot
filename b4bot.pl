#!/usr/bin/perl -w

# CHANGEPROP: Let's uncomment this. We can do it.
# use strict;

package MyBot;
# CHANGEPROP: Let's use carton to install these ;)
use base qw( Bot::BasicBot );
use LWP;
use URI;
use DBI;                        #for MySQL
use Weather::Underground;
use Text::Aspell;
use IMDB::Film;
use URI::Escape;
use WWW::Google::Calculator;
use Love::Match::Calc;

# CHANGEPROP: this is way bad. Why don't we just define them as needed? Or define it once and set_option() as needed.
# Initialising variables used by modules...
# Aspell #
my $speller = Text::Aspell->new;
my $speller1 = Text::Aspell->new;
my $speller2 = Text::Aspell->new;
my $speller3 = Text::Aspell->new;
my $speller4 = Text::Aspell->new;
$speller->set_option('lang','en_GB');
$speller->set_option('sug-mode','fast');
$speller1->set_option('lang','fr_FR');
$speller1->set_option('sug-mode','fast');
$speller2->set_option('lang','is_IS');
$speller2->set_option('sug-mode','fast');
$speller3->set_option('lang','ru_RU');
$speller3->set_option('sug-mode','fast');
$speller4->set_option('lang','cy_GB');
$speller4->set_option('sug-mode','fast');
# End Aspell #

# CHANGEPROP: Config file this shit?
# MySQL Config #
my $sqldatabase = "b4bot";
my $sqlusername="root";
my $sqlpassword="";
my $dsn = "DBI:mysql:$sqldatabase:localhost";
my ($id, $password);
my $dbh = DBI->connect($dsn, $sqlusername, $sqlpassword);
$dbh->{mysql_auto_reconnect} = 1;
# End MySQL Config#

# CHANGEPROP: 'Custom.pm' module for this stuff?
sub uptime(){
  # For the sysinfo command
  use POSIX qw(ceil floor);
  open UPTIME,"<","/proc/uptime" or print $!;
  my @lines = <UPTIME>;
  $uptime = $lines[0];

  close UPTIME;

  @sys_ticks_arr = split(/ /,$uptime);
  #print $sys_ticks_arr[0];
  $sys_ticks = $sys_ticks_arr[0];
  $min = $sys_ticks / 60;
  $hours = $min / 60;
  $days = floor($hours / 24);
  $hours = floor($hours - ($days * 24));
  $min = floor($min - ($days * 60 * 24) - ($hours * 60));

  if ($days != 0) {
    $result = "$days days ";
  }

  if ($hours != 0) {
    $result .= "$hours hours ";
  }
  $result .= "$min minutes";
  return $result;
}

sub said {
  my ($self, $message) = @_;
  if ($message->{body} =~ /`whoami/) {
    return "You are: $message->{raw_nick}";
  }
  if ($message->{body} =~ /\bkills lol\b/) {
    $self->privmsg( $message->{channel} => chr(1)."ACTION dies".chr(1) );
  }
  if ($message->{body} =~ /\beats lol\b/) {
    $self->privmsg( $message->{channel} => chr(1)."ACTION tastes crunchy".chr(1) );
  }
  if ($message->{body} =~ /\bkicks lol\b/) {
    $self->privmsg( $message->{channel} => 'ow' );
  }
  if ($message->{body} =~ /\bgnr\b/) {
    $self->kill( $message->{who} => 'Do NOT say gnr' );
  }
  if ($message->{body} =~ /\bhugs lol\b/) {
    $self->privmsg( $message->{channel} => chr(1)."ACTION hugs $message->{who}".chr(1) );
  }
  if ($message->{body} =~ /\bcuddles lol\b/) {
    $self->privmsg( $message->{channel} => chr(1)."ACTION kisses $message->{who}".chr(1) );
  }

  if ($message->{body} =~ /\blooks at lol\b/) {
    $self->privmsg( $message->{channel} => chr(1)."ACTION looks at $message->{who}".chr(1) );
  }
  if ($message->{body} =~ /\brubs lol\'s tummy\b/) {
    $self->privmsg( $message->{channel} => '*purr*' );
  }
  if (($message->{body} =~ /`meep/) and ($message->{channel} eq "#meep")) {
    $self->privmsg( $message->{channel} => 'meep' );
  }
  # CHANGEPROP: This is running on _every_ _single_ _message
  my $hostname = `hostname -f`; 
  chomp($hostname); 
  my $kernel = `uname -r`;
  chomp($kernel);        
  my $debver = `cat /etc/debian_version`;
  chomp($debver);
  # CHANGEPROP: Unhardcode comchar.
  if ($message->{body} =~ /^`sysinfo/) {
    return "The host I run on ($hostname) has an uptime of: ".uptime().", uses this linux kernel version: $kernel, runs Debian GNU/Linux $debver.";
  }
  my $perlver = `perl -v | grep "This is perl"`;
  if ($message->{body} =~ /^`perlver/) {
    return "$perlver";
  }
  my $fortune = `fortune -s`;
  chomp($fortune);
  if ($message->{body} =~ /^`fortune/) {
    return "$fortune";
  }
  my $longfortune = `fortune -l`;
  chomp($fortune);
  if ($message->{body} =~ /^`longfortune/) {
    return "$longfortune";
  }

  if ($message->{body} =~ /^`calc(.*)/) {
    my $calc = WWW::Google::Calculator->new;
    return "$calc->calc('$1');";
  }
  if ($message->{body} =~ /^`lcalc (.*?) (.+)/) {
    my $firstname = "$1";
    my $secondname = "$2";
    #my $m = lovecalc($firstname,$secondname);# or lovecalc2
    my $m = lovematch($firstname,$secondname); # or lovecalc and lovecalc2
    return "Lovematch for $1 and $2: $m%";
  }

  if (($message->{body} =~ /^\`join(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    $self->join("$1");
  }
  if (($message->{body} =~ /^\`topic(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    $self->privmsg(ChanServ, "topic $message->{channel} $1");
  }
  if (($message->{body} =~ /^\`kick(.*)(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    if (!defined($2)) {
      $self->privmsg(ChanServ, "op $message->{channel}");
      $self->kick($message->{channel}, "$1");
    } else { 
      $self->privmsg(ChanServ, "op $message->{channel}");
      $self->kick($message->{channel}, "$1 $2");
    }
  }
  if (($message->{body} =~ /^\`op(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    if (!defined($1)) {
      $self->privmsg(ChanServ, "op $message->{channel} $message->{who}");
    } else {
      $self->privmsg(ChanServ, "op $message->{channel} $1");
    }
  }
  if (($message->{body} =~ /^\`deop(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    if (!defined($1)) {
      $self->privmsg(ChanServ, "deop $message->{channel} $message->{who}");
    } else {
      $self->privmsg(ChanServ, "deop $message->{channel} $1");
    }
  }
  if (($message->{body} =~ /^\`ban(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    $self->ban($message->{channel}, "$1");
  }
  if (($message->{body} =~ /^\`unban(.*)/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    $self->privmsg(ChanServ, "akick del $message->{channel} $1");
  }
  if ($message->{body} =~ /^\`say(.*)/) {
    $self->privmsg("#goose", $1);
  }

  if ($message->{body} =~ /^\`aquote(.*)/) {  
    if ($1 eq "" ) {
      return "Try adding actual content, genius.";

    } else {
      # CHANGEPROP: implement Schema changes.
      $sth = $dbh->prepare("INSERT INTO quotes(id,meaning) VALUES('NULL',?)");
      $sth->execute($1);
      return "Quote Successfully Added, $message->{who}"

    }
  }

  if ($message->{body} =~ /^\`fquote(.*)/) {
    $out = "";
    $quote = "";
    $num = $1 + 103;
    $sth = $dbh->prepare("SELECT * FROM quotes WHERE id=$num");
    $sth->execute();
    $sth->bind_columns(undef,undef,\$quote);
    $sth->fetch();
    $out = $quote;
    return "[$1] $quote";
  }

  if ($message->{body} =~ /^\`rquote(.*)/) {
    $out = "";
    $quote = "";
    $sth = $dbh->prepare("SELECT * FROM quotes ORDER BY RAND() LIMIT 1");
    $sth->execute();
    $sth->bind_columns(undef,\$id,\$quote);
    $sth->fetch();
    $out = $quote;
    $num = $id - 103;
    return "[$num] $quote";
  }


  if (($message->{body} =~ /^\`part ?(.*)?/) and ($message->{raw_nick} eq 'gewt!gewt@ip-67-202-107-221.chicago-il.gewt.net')) {
    if ($1 eq '') {
      $self->part( '#b4bot' );
    } else {
      $self->part("$1");
    }
  }
  if ($message->{body} =~ /^\`aspell (.*)?/) {
    my $mispelled = $1;
    my $output = "";
    if (!defined($mispelled)) { # <-- if that syntax errors, then look up how to use defined().. i think that's right though.
    } else {
      my @suggestions = $speller->suggest( $mispelled );
      $output .= join(", ", @suggestions);
      $size = scalar @suggestions;
    }
    return "$size suggestion(s) for $mispelled: $output"
  }
  if ($message->{body} =~ /^\`aspellfr (.*)?/) {
    my $mispelled = $1;
    my $output = "";
    if (!defined($mispelled)) { # <-- if that syntax errors, then look up how to use defined().. i think that's right though.
    } else {
      my @suggestions = $speller1->suggest( $mispelled );
      $output .= join(", ", @suggestions);
      $size = scalar @suggestions;
    }
    return "$size suggestion(s) for $mispelled: $output"
  }
  if ($message->{body} =~ /^\`aspellis (.*)?/) {
    my $mispelled = $1;
    my $output = "";
    if (!defined($mispelled)) { # <-- if that syntax errors, then look up how to use defined().. i think that's right though.
    } else {
      my @suggestions = $speller2->suggest( $mispelled );
      $output .= join(", ", @suggestions);
      $size = scalar @suggestions;
    }
    return "$size suggestion(s) for $mispelled: $output"
  }
  if ($message->{body} =~ /^\`aspellru (.*)?/) {
    my $mispelled = $1;
    my $output = "";
    if (!defined($mispelled)) { # <-- if that syntax errors, then look up how to use defined().. i think that's right though.
    } else {
      my @suggestions = $speller3->suggest( $mispelled );
      $output .= join(", ", @suggestions);
      $size = scalar @suggestions;
    }
    return "$size suggestion(s) for $mispelled: $output"
  }
  if ($message->{body} =~ /^\`aspellcy (.*)?/) {
    my $mispelled = $1;
    my $output = "";
    if (!defined($mispelled)) { # <-- if that syntax errors, then look up how to use defined().. i think that's right though.
    } else {
      my @suggestions = $speller4->suggest( $mispelled );
      $output .= join(", ", @suggestions);
      $size = scalar @suggestions;
    }
    return "$size suggestion(s) for $mispelled: $output"
  }
  if ($message->{body} =~ /^\`ping(.*)/) {
    return "Pong"
  }
  if ($message->{body} =~ /^`weather (\S.+)/) { #get weather from Weather::Underground
    $weather = Weather::Underground->new(
      place => $1,
      debug => 0,
    ) || print "Could not create weahter object.\n";
    $fail = 0;
    $arrayresults = $weather->get_weather() or $fail=1;
    if ($fail == 1) {
      return "could not fetch the weather for $1.";
    } else {
      $to_chan = "Weather for $arrayresults->[0]->{place}: Current Conditions: ".chr(2).$arrayresults->[0]->{conditions}.chr(2).". Temperature: ".chr(2).$arrayresults->[0]->{temperature_fahrenheit}." ($arrayresults->[0]->{temperature_celsius}c)".chr(2).". Wind is ".chr(2).$arrayresults->[0]->{wind_direction}.chr(2). " at ".chr(2).$arrayresults->[0]->{wind_milesperhour}."MPH.".chr(2)." Clouds ".chr(2).$arrayresults->[0]->{clouds}.chr(2)." Visibility: ".chr(2).$arrayresults->[0]->{visibility_miles}.chr(2)." Miles. Moon Phase: ".chr(2).$arrayresults->[0]->{moonphase}.chr(2).". Sunrise: ".chr(2).$arrayresults->[0]->{sunrise}.chr(2).". Sunset: ".chr(2).$arrayresults->[0]->{sunset}.chr(2).".";
      return "$to_chan";
    }
  }
  if ($message->{body} =~ /^`imdb (\S.+)/) { #get weather from Weather::Underground
    my $imdb = new IMDB::Film(      crit            => $1,
                                    user_agent      => 'Opera/8.x',
                                    timeout         => 2,
                                    debug           => 1,
                                    cache           => 0
                                  );
    my $title = $imdb->title();
    my $year = $imdb->year(); 
    my $url = uri_escape( $1 ); 
    my $id = $imdb->id();
    my $plot = $imdb->plot();
    my $rating = $imdb->rating();
    my $duration = $imdb->duration();
    if ($imdb->status) {
      return "Title: $title, Rating: $rating, Year: $year, Duration: $duration Summary: $plot, URL: http://www.imdb.com/title/tt$id";
    } else {
      return "Couldn't find $1.";
    }
  }
  if ($message->{body} =~ /^\`whatis\s(.*)/) { #fetch something from the DB
    $out = "";
    $meaning = "";
    $action = "false";
    my $sth = $dbh->prepare("SELECT * FROM factoids WHERE name=? ORDER BY id desc LIMIT 1");
    $sth->execute($1);
    $sth->bind_columns(undef, undef, undef, \$meaning, \$action);
    $sth->fetch();
    $out = "";
    if ($action eq "true") {
      $actout = 1;
      $out = $meaning;
    } else {
      #action is false
      $actout = 0;
      $out = $meaning;
    }
    if ($out ne "") {
      if ($actout == 1) {
        return chr(1)."ACTION $out".chr(1);
      } else {
        return "$1 is $out";
      }
    } else { 
      return "I have no idea what $1 is. WTF is $1?"; 
    }
  }
  if ($message->{body} =~ /^\`whatare\s(.*)/) { #fetch something from the DB
    $out = "";
    $meaning = "";
    $action = "false";
    my $sth = $dbh->prepare("SELECT * FROM factoids WHERE name=? ORDER BY id desc LIMIT 1");
    $sth->execute($1);
    $sth->bind_columns(undef, undef, undef, \$meaning, \$action);
    $sth->fetch();
    $out = "";
    if ($action eq "true") {
      $actout = 1;
      $out = $meaning;
    } else {
      #action is false
      $actout = 0;
      $out = $meaning;
    }
    if ($out ne "") {
      if ($actout == 1) {
        $self->emote("$message->{channel}", "$out");
      } else {
        return "$1 are $out";
      }
    } else { 
      return "I have no idea what $1 are. WTF are $1?"; 
    }
  }
}

sub help { "I'm annoying, and I hunger for more deep-fried Chinamen." }

my $bot = MyBot->new(
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
@bots = ($bot);
foreach $bot (@bots) {
  $bot->run();
}
use POE;
$poe_kernel->run();

