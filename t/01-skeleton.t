package Test::Skeleton;
use strict;
use warnings;
use parent 'Skeleton::CoC';

sub basedir { $_[0]->{basedir} }

__PACKAGE__->define_target('package' => [] => sub {
    my ($self, $pkg) = @_;
    my $path = join "/", split /::/, $pkg;
    $self->basedir . "/lib/$path.pm";
});

__PACKAGE__->define_target('script' => ['package'] => sub {
    my ($self, $script) = @_;
    $self->basedir . "/scripts/$script";
});

package main;
use strict;
use warnings;
use Test::More;
use File::Temp;

subtest "generate test" => sub {
    my $skel = Test::Skeleton->new(
        project => "Test",
        basedir => File::Temp::tempdir(CLEANUP => 1),
    );
    my $tmpdir = $skel->basedir;
    $skel->parse_option(qw(package YourApp::Skeleton));
    $skel->generate;
    ok(-f "$tmpdir/lib/YourApp/Skeleton.pm", "package is generated");
};

subtest "generate test" => sub {
    my $skel = Test::Skeleton->new(
        project => "Test",
        basedir => File::Temp::tempdir(CLEANUP => 1),
    );
    my $tmpdir = $skel->basedir;
    $skel->parse_option(qw(package YourApp::Skeleton script skeleton.pl));
    $skel->generate;
    ok(-f "$tmpdir/lib/YourApp/Skeleton.pm", "package is generated");
    ok(-f "$tmpdir/scripts/skeleton.pl", "script is generated");
};

done_testing;

package Test::Skeleton;
__DATA__

@@ package
? my $self = shift;
package <?= $self->package ?>;
use strict;
use warnings;
use parent qw(Skeleton::CoC);

__PACKAGE__->define_target('target' => [] => sub {
    my ($self, $value) = @_;
});

@@ script
? my $self = shift;
use strict;
use warnings;
use <? $self->package ?>;

my $skel = <? $self->package ?>->new(
);
$skel->parse_option(@ARGV);
$skel->generate;

