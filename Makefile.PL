use inc::Module::Install;
version '5.005';

requires(
  'Bot::BasicBot',
  'DBI',
  'Weather::Underground',
  'Text::Aspell',
  'IMDB::Film',
  'WWW::Google::Calculator',
  'Love::Match::Calc');

auto_install;
WriteAll;
