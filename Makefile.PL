use inc::Module::Install;

all_from 'lib/CGI/Application/Plugin/Header.pm';
readme_from 'lib/CGI/Application/Plugin/Header.pm';

repository 'https://github.com/anazawa/p5-CGI-Application-Plugin-Header';

requires 'parent';
requires 'Exporter';
requires 'CGI::Header';

test_requires 'Test::More';
test_requires 'Test::Pod';
test_requires 'CGI::Application';

tests 't/*.t xt/*.t';

WriteAll;
