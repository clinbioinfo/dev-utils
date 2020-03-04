#!/usr/bin/env perl
use strict;

my $section = $ARGV[0];
my $param = $ARGV[1];
my $value = $ARGV[2];

if (!defined($section)){
    do {

        print "What is the name of the section? ";
        $section = <STDIN>;
        chomp $section;
    } while ((!defined($section)) || ($section eq ''));
}


if (!defined($param)){
    do {
        print "What is the name of the param? ";
        $param = <STDIN>;
        chomp $param;
    } while ((!defined($param)) || ($param eq ''));
}

if (!defined($value)){
    do {

        print "What is the value? ";
        $value = <STDIN>;
        chomp $value;
    } while ((!defined($value)) || ($value eq ''));
}

print "##\n## Add this to the module\n##\n";
print "use constant DEFAULT_" . uc($param) . " => '" . $value . "';\n\n";
print "sub _get_" . lc($param) . " {\n";
print '    my $self = shift;' . "\n";
print '    if (! exists $self->{_' . lc($param) . '}){' . "\n";
print '        my $val = $self->{_config_manager}->get' . ucfirst(lc($param)) . "();\n";
print '        if ((!defined($val)) || ($val eq \'\')){' . "\n";
print '            $val = DEFAULT_' . uc($param) . ";\n";
print '            $self->{_logger}->info("Could not derive the value for param \'' . $param . '\' from section \'' . $section . '\' in the configuration file");'  . "\n";
print '        }' . "\n";
print '        $self->{_' . lc($param) . '} = $val;' . "\n";
print '    }' . "\n";
print '    return $self->{_' . lc($param) . '};' . "\n";
print '}' . "\n\n";


print "##\n## Add this to the Config::Manager module:\n##\n";
print "sub get" . ucfirst(lc($param)) . " {\n";
print '    my $self = shift;' . "\n";
print '    return $self->{_config}->param(\'' . $section . '\', \'' . $param . '\');' . "\n";
print '}' . "\n\n";


print "##\n## Add this to the conf/config.ini file:\n##\n";
print '[' . $section . ']' . "\n\n";
print ';;' . "\n";
print ';; ADD YOUR COMMENT HERE' . "\n";
print ';;' . "\n";
print $param . '=' . $value . "\n";


exit(0);
