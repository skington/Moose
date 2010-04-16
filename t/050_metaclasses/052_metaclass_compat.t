#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

our $called = 0;
{
    package Foo::Trait::Constructor;
    use Moose::Role;

    around _generate_BUILDALL => sub {
        my $orig = shift;
        my $self = shift;
        return $self->$orig(@_) . '$::called++;';
    }
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            constructor => ['Foo::Trait::Constructor'],
        }
    );
}

Foo->new;
is($called, 0, "no calls before inlining");
Foo->meta->make_immutable;

Foo->new;
is($called, 1, "inlined constructor has trait modifications");

ok(Foo->meta->constructor_class->meta->does_role('Foo::Trait::Constructor'),
   "class has correct constructor traits");

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';
}

$called = 0;

Foo::Sub->new;
is($called, 0, "no calls before inlining");

Foo::Sub->meta->make_immutable;

Foo::Sub->new;
is($called, 1, "inherits constructor trait properly");

ok(Foo::Sub->meta->constructor_class->meta->can('does_role')
&& Foo::Sub->meta->constructor_class->meta->does_role('Foo::Trait::Constructor'),
   "subclass inherits constructor traits");

{
    package Foo2::Role;
    use Moose::Role;
}
{
    package Foo2;
    use Moose -traits => ['Foo2::Role'];
}
{
    package Bar2;
    use Moose;
}
{
    package Baz2;
    use Moose;
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::lives_ok { $meta->superclasses('Bar2') } "can still set superclasses";
    ::isa_ok($meta, Bar2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role'],
                "still have the role attached");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Foo3::Role;
    use Moose::Role;
}
{
    package Bar3;
    use Moose -traits => ['Foo3::Role'];
}
{
    package Baz3;
    use Moose -traits => ['Foo3::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Bar3') } "can still set superclasses";
    ::isa_ok($meta, Bar3->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Quux3;
    use Moose;
}
{
    package Quuux3;
    use Moose -traits => ['Foo3::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Quux3') } "can still set superclasses";
    ::isa_ok($meta, Quux3->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}

{
    package Foo4::Role;
    use Moose::Role;
}
{
    package Foo4;
    use Moose -traits => ['Foo4::Role'];
    __PACKAGE__->meta->make_immutable;
}
{
    package Bar4;
    use Moose;
}
{
    package Baz4;
    use Moose;
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::lives_ok { $meta->superclasses('Bar4') } "can still set superclasses";
    ::isa_ok($meta, Bar4->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role'],
                "still have the role attached");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Foo5::Role;
    use Moose::Role;
}
{
    package Bar5;
    use Moose -traits => ['Foo5::Role'];
}
{
    package Baz5;
    use Moose -traits => ['Foo5::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Bar5') } "can still set superclasses";
    ::isa_ok($meta, Bar5->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Quux5;
    use Moose;
}
{
    package Quuux5;
    use Moose -traits => ['Foo5::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Quux5') } "can still set superclasses";
    ::isa_ok($meta, Quux5->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}

done_testing;