use inc::Module::Install;
version '5.005';

feature     'Feature2',
  -default    => 0,
  'Bot::BasicBot' => 0;

requires(
  'DBI',
  'Weather::Underground',
  'Text::Aspell',
  'IMDB::Film',
  'WWW::Google::Calculator',
  'Love::Match::Calc');

auto_install;
WriteAll;
