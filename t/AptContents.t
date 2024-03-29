#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 23;

BEGIN {
    use_ok 'Debian::AptContents';
};

use FindBin qw($Bin);
use File::Touch qw(touch);

unlink("$Bin/Contents.cache");

sub instance
{
    Debian::AptContents->new({
        homedir => $Bin,
        contents_dir    => "$Bin/contents",
        verbose => 0,
        sources    => "$Bin/contents/sources.list",
        @_,
    });
}

eval { Debian::AptContents->new() };
ok( $@, 'AptContents->new with no homedir dies' );
like( $@, qr/No homedir given/, 'should say why it died' );

my $apt_contents = instance( contents_dir => 'non-existent' );

isnt( $apt_contents, undef, 'should create with no contents' );

is( $apt_contents->cache, undef, 'but should contain no cache' );

is( $apt_contents->cache, undef, 'should have no cache when no dists found' );

is(
    $apt_contents->repo_source_to_contents_path(
        'deb     http://debian.cihar.com/ unstable main contrib non-free'),
    'debian.cihar.com_dists_unstable',
    'source line conversion 1',
);

is(
    $apt_contents->repo_source_to_contents_path(
        'deb     http://kernel-archive.buildserver.net/debian-kernel trunk main'),
    'kernel-archive.buildserver.net_debian-kernel_dists_trunk',
    'source line conversion 2',
);

is(
    $apt_contents->repo_source_to_contents_path(
        'deb     http://www.debian-multimedia.org stable main'),
    'www.debian-multimedia.org_dists_stable',
    'source line conversion 3',
);

is(
    $apt_contents->repo_source_to_contents_path(
        'deb     http://ftp.debian-unofficial.org/debian testing main contrib non-free restricted'),
    'ftp.debian-unofficial.org_debian_dists_testing',
    'source line conversion 4',
);

is(
    $apt_contents->repo_source_to_contents_path(
        'deb     http://ftp.de.debian.org/debian/ unstable main contrib non-free'),
    'ftp.de.debian.org_debian_dists_unstable',
    'source line conversion 5',
);

is(
    $apt_contents->repo_source_to_contents_path(
        'deb file:/home/jason/debian stable main contrib non-free'),
    '_home_jason_debian_dists_stable',
    'source line conversion 6',
);

$apt_contents = instance();

is_deeply(
    $apt_contents->contents_files,
    [ sort glob "$Bin/contents/*Contents*" ],
    'contents in a dir'
);

ok( -f "$Bin/Contents.cache", 'Contents.cache created' );

is( $apt_contents->source, 'parsed files', 'no cache was used' );

$apt_contents = instance();

is( $apt_contents->source, 'cache', 'cache was used' );

sleep(1);   # allow the clock to tick so the timestamp actually differs
touch( glob "$Bin/contents/*Contents*" );

$apt_contents = instance();

is( $apt_contents->source, 'parsed files', 'cache updated' );

is_deeply(
    [ $apt_contents->find_file_packages('Moose.pm')],
    [ 'libmoose-perl' ],
    'Moose found by find_file_packages' );

is( $apt_contents->find_perl_module_package('Moose'), 'libmoose-perl', 'Moose fund by module name' );

is_deeply(
    $apt_contents->get_contents_files,
    [   "$Bin/contents/test_debian_dists_sid_Contents",
        "$Bin/contents/test_debian_dists_testing_Contents"
    ]
);

is_deeply(
    [ $apt_contents->find_file_packages('GD.pm') ],
    [ 'libgd-gd2-noxpm-perl', 'libgd-gd2-perl' ],
    "GD.pm is in libdg-gd2[-noxpm]-perl"
);

is( $apt_contents->find_perl_module_package('GD'),
    'libgd-gd2-noxpm-perl | libgd-gd2-perl',
    'Alternative dependency for module found in multiple packages'
);

ok( unlink "$Bin/Contents.cache", 'Contents.cache unlnked' );
