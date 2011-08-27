use inc::Module::Install;
version '5.005';
license 'Public Domain';

requires(
  'Bot::BasicBot',
  'DBI',
  'Weather::Underground',
  'Text::Aspell',
  'IMDB::Film',
  'WWW::Google::Calculator',
  'Love::Match::Calc',
  'YAML',
  'Proc::Daemon',
  'Net::IP',
  'Weather::Google',
  'HTML::Entities',
  'Image::Size',
  'Net::Dict',
);

auto_install;
WriteAll;
