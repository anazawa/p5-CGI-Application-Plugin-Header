use inc::Module::Install;

all_from 'lib/CGI/Application/Plugin/Header.pm';

repository 'https://github.com/anazawa/p5-CGI-Application-Plugin-Header';

tests 't/*.t xt/*.t';

WriteAll;
