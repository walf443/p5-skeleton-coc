package Skeleton::CoC;
use strict;
use warnings;
use Data::Section::Simple qw();
use Text::MicroTemplate;
use Log::Minimal qw(infof warnf critf );
use Path::Class;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub parse_option {
    my ($self, %option) = @_;
    for my $target ( keys %option ) {
        $self->{$target} = $option{$target};
    }
}

sub generate {
    my ($self, ) = @_;

    for my $target ( $self->targets ) {
        next unless $self->$target;
        my @depends = $self->get_depends($target);
        for my $depend ( @depends ) {
            unless ( $self->$depend ) {
                critf("target $target\'s dependency $depend is not exist");
                exit(1);
            }
        }
        my $path = $self->get_path($target, $self->{$target});
        if ( -f $path ) {
            infof("$path is already exists!!");
        } else {
            my $renderer = $self->get_template($target);
            my $result = $renderer->($self);
            my $file = file($path);
            $file->parent->mkpath;
            my $io = $file->openw;
            $io->write($result);
            $io->close;
            infof("generate $path");
        }
    }
}

sub targets {
    my ($self, ) = @_;
    my @targets = keys %{ $self };
    my @results;
    for my $target ( @targets ) {
        next unless $self->can("get_path_$target");
        push @results, $target;
        push @results, $self->_resolve_dependency($target);
    }
    return reverse @results;
}

sub _resolve_dependency {
    my ($self, $target) = @_;
    my @depends = $self->get_depends($target);
    my @array;
    for my $depend ( @depends ) {
        push @array, $depend;
        push @array, $self->_resolve_dependency($depend);
    }
    return @array;
}

sub define_target {
    my ($class, $name, $depends, $code) = @_;

    no strict 'refs';
    *{"$class\::$name" } = sub { my $self = shift; $self->{$name} };
    *{"$class\::get_path_$name"} = sub {
        my $self = shift;
        return $code->($self, @_);
    };
    *{"$class\::get_depends_$name"} = sub { return $depends; };
}

sub get_path {
    my ($self, $target, $value) = @_;
    my $meth = "get_path_$target";
    return $self->$meth($value);
}

sub get_depends {
    my ($self, $target) = @_;
    my $meth = "get_depends_$target";
    my $result;
    if ( $self->can($meth) ) {
        $result = $self->$meth();
    }
    return wantarray ? @{ $result || [] } : $result;
}

sub get_template {
    my ($self, $sec) = @_;
    my $template = Data::Section::Simple->new(ref $self)->get_data_section($sec)
        or die "Can't get section: $sec";

    return Text::MicroTemplate::build_mt($template);
}

1;
__END__

=head1 NAME

Skeleton::CoC - support creating skelton for project.

=head1 SYNOPSIS

    package YourApp::Skeleton;
    use parent(Skeleton::CoC);
    use String::CamelCase qw();

    __PACKAGE__->define_target('controller' => [], sub {
        my ($self, $pkg) = @_;
        my $path = join "/", split /::/, $pkg;
        return "lib/YourApp/C/$path.pm";
    });

    __PACKAGE__->define_target('action' => ['controller'], sub {
        my ($self, $str) = @_;
        my $path = join "/", map { String::CamelCase::decamelize($_) } split /::/, $self->controller;
        return "assets/tmpl/$path/$str.html";
    });

    __DATA__

    @controller
    ? my $self = shift; # $self is a Skeleton::CoC.
    package <? $self->project ?>::C::<?= $self->controller ?>;
    use strict;
    use warnings;
    use parent qw(YourApp::C);

    ? if ( $self->action ) {

    sub dispatch_<?= $self->action ?> {
        my ($self, ) = @_;
    }

    ? }
    1;

    @@ action
    [% INCLUDE "include/header.html" %]
    [% INCLUDE "include/footer.html" %]

in your skeleton.pl

    strict;
    warnings;
    use YourApp::Skeleton;
    my $skeleton = YourApp::Skeleton->new(
        project => "YourApp",
        action => "index",
    );
    $skeleton->parse_options(@ARGV);
    $skeleton->generate;

and run followings:

    $ ./skeleton.pl controller Foo::Bar
    # => generate lib/YourApp/C/Foo/Bar.pm

    $ ./skeleton.pl controller Foo::Bar action baz
    # => generate lib/YourApp/C/Foo/Bar.pm
    #    generate assets/tmpl/foo/bar/baz.html

=head1 DESCRIPTION

Skeleton::CoC is

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
