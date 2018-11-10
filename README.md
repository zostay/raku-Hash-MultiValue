NAME
====

Hash::MultiValue - Store multiple values per key, but act like a regular hash too

SYNOPSIS
========

    my %mv := Hash::MultiValue.from-pairs: (a => 1, b => 2, c => 3, a => 4);

    say %mv<a>; # 4
    say %mv<b>; # 2

    say %mv('a').join(', '); # 1, 4
    say %mv('b').join(', '); # 2

    %mv<a>   = 5;
    %mv<d>   = 6;
    %mv('e') = 7, 8, 9;

    say %mv.all-pairs».fmt("%s: %s").join("\n");
    # a: 5
    # b: 2
    # c: 3
    # d: 6
    # e: 7
    # e: 8
    # e: 9

DESCRIPTION
===========

This class is useful in cases where a program needs to have a hash that may or may not have multiple values per key, but frequently assumes only one value per key. This is commonly the case when dealing with URI query strings. This class also generally preserves the order the keys are encountered, which can also be a useful characteristic when working with query strings.

If some code is handed this object where a common [Associative](Associative) object (like a [Hash](Hash)) is expected, it will work as expected. Each value will only have a single value available. However, when one of these objects is used as function or using the various `.all-*` alternative methods, the full multi-valued contents of the keys can be fetched, modified, and iterated.

This class makes no guarantees to preserve the order of keys. However, the order of the multiple values stored within a key is guaranteed to be preserved. If you require key order to be preserved, you may want to look into [ArrayHash](ArrayHash) instead.

Methods
=======

method new
----------

    multi method new(Hash::MultiValue:U:) returns Hash::MultiValue:D
    multi method new(Hash::MultiValue:U: :@pairs!) returns Hash::MultiValue:D
    multi method new(Hash::MultiValue:U: :@kv!) returns Hash::MultiValue:D
    multi method new(Hash::MultiValue:U: :%mixed-hash!, :$iterate = Iterable, :&iterator) returns Hash::MultiValue:D

This method constructs a multi-value hash. If called with no arguments, an empty hash will be constructed.

    my %empty := Hash::MultiValue.new;

If called with the named `pairs` argument, then the given pairs will be used to instantiate the list. This is similar to calling `from-pairs` with the given list..

    my %from-pairs := Hash::MultiValue.new(
        pairs => (a => 1, b => 2, a => 3),
    );

If called with the named `kv` argument, then the given list must have an even number of elements. The even-indexed items will be treated as keys, and the following odd-indexed items will be treated as the value for the preceding key. This is similar to calling `from-kv`.

    my %from-kv = Hash::MultiValue.new(
        kv => ('a', 1, 'b', 2, 'a', 3),
    );

If called with the named `mixed-hash` argument, then the given hash will be treated as a mixed value hash. A mixed value hash is complicated, so using it to initialize this data structure is not ideal.

In order to initialize from such a structure, every value in the given hash must be evaluted by type. If the type of the value matches the one found in `$iterator` ([Iterable](Iterable) by default), then the key will be inserted multiple times, one for each item iterated. The iteration will be handled by just looping over the values using a `map` operation. You can provide your own `&iterator` as well, which will be called for each value matching `$iterator`. The first argument will be key to return and the second will be the value that needs to be iterated. The `&terator` should return a `Seq` of `Pair`s.

    my %from-mixed := Hash::MultiValue.new(
        mixed-hash => {
            a => [ 1, 3 ],
            b => 2,
        },
    );

method from-pairs
-----------------

    method from-pairs(Hash::MultiValue:U: *@pairs) returns Hash::MultiValue:D

This takes a list of pairs and constructs a [Hash::MultiValue](Hash::MultiValue) object from it. Multiple pairs with the same key may be included in this list and all values will be associated with that key.

It should be noted that you may need to be a little careful with how you pass your pairs into this method. Perl 6 treats anything that looks like a named argument as a named argument. Here's a quick example of what works and what doesn't:

    # THIS
    my %h := Hash::MultiValue.from-pairs: (a => 1, b => 2, a => 3);
    # OR THIS
    my %h := Hash::MultiValue.from-pairs((a => 1, b => 2, a => 3));
    # OR THIS
    my %h := Hash::MultiValue.from-pairs('a' => 1, 'b' => 2, 'a' => 3);
    # OR THIS
    my @a := (a => 1, b => 2, a => 3);
    my %h := Hash::MultiValue.from-pairs(@a);

    # BUT NOT
    my %h := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    # ALSO NOT
    my %h := Hash::MultiValue.from-pairs(|@a);

To protect from accidentally passing these as named arguments, the method will fail if any named arguments are detected.

### method from-pairs

```perl6
method from-pairs(
    *@pairs,
    *%badness
) returns Hash::MultiValue:D
```

Construct a Hash::MultiValue object from a list of pairs

method from-kv
--------------

    method from-kv(Hash::MultiValue:U: +@kv) returns Hash::MultiValue:D

This takes a list of keys and values in a single list and turns them into pairs. The given list of items must have an even number of elements or the method will fail.

The even-indexed items will be treated as keys, and the following odd-indexed items will be treated as the value for the preceding key. This is similar to calling `from-kv`.

method from-mixed-hash
----------------------

    multi method from-mixed-hash(Hash::MultiValue:U: %hash, :$iterate = Iterable, :&iterate) returns Hash::MultiValue:D
    multi method from-mixed-hash(Hash::MultiValue:U: *%hash) returns Hash::MultiValue:D

This takes a hash and constructs a new [Hash::MultiValue](Hash::MultiValue) from it as a mixed-value hash. A mixed value hash is complicated, so using it to initialize this data structure is not ideal.

In order to initialize from such a structure, every value in the given hash must be evaluted by type. If the type of the value matches the one found in `$iterator` ([Iterable](Iterable) by default), then the key will be inserted multiple times, one for each item iterated. The iteration will be handled by just looping over the values using a `map` operation. You can provide your own `&iterator` as well, which will be called for each value matching `$iterator`. The first argument will be key to return and the second will be the value that needs to be iterated. The `&terator` should return a `Seq` of `Pair`s.

    my %from-mixed := Hash::MultiValue.from-mixed-hash(
        a => [ 1, 3 ],
        b => 2,
    );

    # The above is basically identical to:
    # Hash::MultiValue.from-pairs: (a => 1, a => 3, b => 2);

**Caution:** If you use the slurpy version of this method, you have no additional named options. Passing `iterate` or `iterator` will just result in those being put into the data structure.

### multi method from-mixed-hash

```perl6
multi method from-mixed-hash(
    %mixed-hash,
    :$iterate = Iterable,
    :&iterator = { ... }
) returns Hash::MultiValue:D
```

Construct a Hash::MultiValue object from a mixed value hash

### multi method from-mixed-hash

```perl6
multi method from-mixed-hash(
    *%mixed-hash
) returns Hash::MultiValue:D
```

Construct a Hash::MultiValue object from a mixed value hash

method postcircumfix:<{ }>
--------------------------

    method postcircumfix:<{ }> (Hash::MultiValue:D: %key) is rw

Whenever reading or writing keys using the `{ }` operator, the hash will behave as a regular built-in [Hash](Hash). Any write will overwrite all values that have been set on the multi-value hash with a single value.

    my %mv := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    %mv<a> = 4;
    say %mv('a').join(', '); # 4

Any read will only read a single value, even if multiple values are stored for that key.

    my %mv := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    say %mv<a>; # 3

Of those values the last value will always be used. This is in keeping with the usual semantics of what happens when you add two pairs with the same key twice in Perl 6.

You may also use the `:delete` and `:exists` adverbs with these objects.

    my %mv := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    say %mv<a> :delete; # 3 (both 1 and 3 are gone)
    say %mv<b> :exists; # True

Binding is also supported. For example,

    my $a = 4;
    %mv<a> := $a;
    $a = 5;
    say %mv<a>; # 4

method postcircumfix:<( )>
--------------------------

    method postcircumfix:<( )> (Hash::MultiValue:D: $key) is rw

The `( )` operator may be used in a fashion very similar to `{ }`, but in that it always works with multiple values. You may use it to read multiple values from the object:

    my %mv := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    say %mv('a').join(', '); # 1, 3

You may also use it to write multiple values, which will replace all values currently set for that key:

    my %mv := Hash::MultiValue.from-pairs(a => 1, b => 2, a => 3);
    %mv('a') = 4, 5;
    %mv('b') = 6, 7;
    %mv('c') = 8;
    say %mv('a').join(', '); # 4, 5
    say %mv('b').join(', '); # 6, 7
    say %mv('c').join(', '); # 8

At this time, this operator does not support slices (i.e., using a [Range](Range) or [List](List) of keys to get values for more than one key at once). This might be supported in the future.

method kv
---------

Returns a list alternating between key and value. Each key will only be listed once with a singular value. See [/method all-kv](/method all-kv) for a multi-value version.

method pairs
------------

Returns a list of [Pair](Pair) objects. Each key is returned just once pointing to the last (or only) value in the multi-value hash. See [/method all-pairs](/method all-pairs) for the multi-value version.

method antipairs
----------------

This is identical to [/method pairs](/method pairs), but with the value and keys swapped.

method invert
-------------

This is a synonym for [/method antipairs](/method antipairs).

method keys
-----------

Returns a list of keys. Each key is returned exactly once. See [/method all-keys](/method all-keys) for the multi-value version.

method values
-------------

Returns a list of values. Only the last value of a multi-value key is returned. See [/method all-values](/method all-values) for the multi-value version.

method all-kv
-------------

Returns a list alternating between key and value. Multi-value key will be listed more than once.

method all-pairs
----------------

Returns a list of [Pair](Pair) objects. Multi-value keys will be returned multiple times, once for each value associated with the key.

method all-antipairs
--------------------

This is identical to [/method all-pairs](/method all-pairs), but with key and value reversed.

method all-invert
-----------------

This is a synonym for [/method all-antipairs](/method all-antipairs).

method keys
-----------

This returns a list of keys. Multi-valued keys will be returned more than once. If you want the unique key list, you want to see [/method keys](/method keys).

method values
-------------

This returns a list of all values, including the multiple values on a single key.

method push
-----------

    method push(*@values)

This adds new pairs to the list. Any pairs given with a key matching an existing key will cause the single value version of that key to be replaced with the new value. This never overwrites existing values.

method perl
-----------

Returns code as a string that can be evaluated with `EVAL` to recreate the object.

method gist
-----------

Like [/method perl](/method perl), but only includes up to the first 100 keys.

