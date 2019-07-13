# Perl6 Doc Tools [![CI Status](https://circleci.com/gh/antoniogamiz/Perl6-Documentable.svg?style=shield)](https://circleci.com/gh/antoniogamiz/Perl6-Documentable) [![Build Status](https://travis-ci.org/antoniogamiz/Perl6-Documentable.svg?branch=master)](https://travis-ci.org/antoniogamiz/Perl6-Documentable) [![artistic](https://img.shields.io/badge/license-Artistic%202.0-blue.svg?style=flat)](https://opensource.org/licenses/Artistic-2.0)

In this repository you can find all logic responsible of generate the [official documentation of Perl6](https://docs.perl6.org/).

## Table of contents

- [Installation](#installation)
- [Usage](#usage)
- [Perl6::Documentable](#perl6documentable)
- [Perl6::Documentable::Registry](#perl6documentableregistry)
  - [Consulting methods](#consulting-methods)
  - [Indexing methods](#indexing-methods)
- [Perl6::Documentable::Processing](#perl6documentableprocessing)
- [Perl6::Documentable::To::HTML](#perl6documentabletohtml)
- [Perl6::Utils](#perl6utils)
- [Resources](#resources)
  - [Templates](#templates)
  - [HTML](#html)
- [Tests](#ŧests)
- [Authors](#authors)

## Installation

```
$ zef install Perl6::Documentable
```

## Usage

Before generate any documents you should execute:

```
documentable setup
```

in order to download the necessary files to the site (CSS, svg, ...). Alternatively, you can add your own.

```
documentable setup
documentable start [--topdir=<Str>] [-v|--verbose] [-c|--cache] [-p|--pods] [-s|--search-index]
                 [-i|--indexes] [-t|--type-images] [-f|--force] [-a|--all] [--highlight] [-k|--kind]
```

#### --topdir <Str>

Directory where the pod files are stored. Set to `doc` by default.

#### -v, --verbose

Be more verbose/talkative during the operation. Useful for debugging
and seeing what's going on "under the hood".

#### -c, --cache

Usage of a cache of pod ([cached used](https://github.com/finanalyst/pod-cached)). Set to `True`
by default.

#### -p, --pods

Generate one HTML page for every pod file.

#### -s, --search-index

Generate the search file `search.js`.

#### -i, --indexes

Generate all index files.

#### -t, --type-images

Generate and write (if necessary) all typegraph svg files.

#### -f, --force

If specified, typegraph svg files will be forcibly generated and written.

#### --highlight

If specified, code blocks will be highlighted using [atom-language-perl6](https://github.com/perl6/atom-language-perl6).

#### -k, --kind

If specified, kind files will be written for `syntax` and `routine`.

#### -a, --all

Equivalent to `-p -s -i -t`.

## Perl6::Documentable

### SYNOPSIS

```perl6
use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Load;

# get a pod source
my $pod = load("some-amaizing-pod-file.pod6")[0];

# create the first Documentable object from a pod
my $doc = process-pod-source(
    kind => "type",
    pod  => $pod,
    filename => "some-amazing-pod-file"
);

# and use it!
$doc.defs;
```

### DESCRIPTION

Perl6::Documentable represents a piece of Perl 6 that is documented. It contains meta data about what is documented (for example (kind => 'type', subkinds => ['class'], name => 'Code') and in \$.pod a reference to the current documentation.

### Perl6::Documentable

```perl6
    has Str  $.kind;
    has Str  @.subkinds;
    has Str  @.categories;

    has Str  $.name;
    has Str  $.url;
    has      $.pod;
    has Bool $.pod-is-complete;
    has Str  $.summary = '';

    has $.origin;

    has @.defs;
    has @.refs;
```

#### Str \$.kind

This value is highly used in the documentation process, it can take six different values: `[language programs type syntax reference routine]`.

The first three ones are **only** set when the source pod files are processed (see [process-pod-dir](#sub-process-pod-dir) and [process-pod-source](#sub-process-pod-source)). In this case, the value of `kind` can tell you where this pod source comes from.

`syntax` and `routine` values are only set by [find-definitions](#sub-find-definitions), when a new definition is found.

`reference` is only set by [register-reference](#sub-register-reference), whenever a new reference element is found.

#### Str @.subkinds

Can take one of the following values: `<infix prefix postfix circumfix postcircumfix listop sub method term routine trait submethod constant variable twigil declarator quote>`.

In addition, it can take the value of the meta part in a `X<>` definition (see [find-definitions](#sub-find-definitions)).

#### Str @.categories

It is assigned with what [parse-definition-header](#sub-parse-definition-header)returns. Its value will be one of [this list](https://gist.github.com/antoniogamiz/b01f8e088501d5736c4c9194eb6a0671).

In addition, if the [Perl6::Documentable](#perl6documentable) object comes from a type pod source, this category will be replaced by the information given by `Perl6::TypeGraph` (see [process-pod-source](#sub-process-pod-source)).

#### Str \$.name

Name of the Pod. It is usually set to the filename without the extension `.pod6`.

See [parse-definition-header](#sub-parse-definition-header) returns).

#### Str \$.url

Work in progress :D.

#### \$.pod

Perl6 pod structure.

#### Bool \$.pod-is-complete

Indicates if the Pod represented by the [Perl6::Documentable](#perl6documentable) object is completed. A Pod is completed if itrepresents the whole pod source, that's to say, the `$.pod` attribute contains an entire pod file.

It will be considered incomplete if the [Perl6::Documentable](#perl6documentable) object represents a definition or a reference. In that case the `$.pod` attribute will only contain the part corresponding to the definition or the reference.

#### Str \$.summary

Subtitle of the pod.

```perl6
=begin pod :tag<tutorial>

=TITLE  Perl 6 by example

=SUBTITLE A basic introductory example of a Perl 6 program

...

=end pod

```

In this case `$summary="A basic introductory example of a Perl 6 program"`.

#### \$.origin

Documentable object that this one was extracted from, if any. This is used for nested definitions. Let's see an example:

```perl6
=begin pod

Every one of this valid definitions is represented by a Perl6::Documentable object after being processed.

=head1 method a

=head2 method b

    In both cases $origin points to the Documentable object representing
    the method a.

=head2 method c

=head1 method d

    $origin in this case points to the Perl6::Documentable object
    containing the pod source.

=end pod
```

Two or more definitions are nested if they appears one after another and if the second one has a greater heading level than the second one.

#### Array @.defs

It contains all definitions found in [\$.pod](#pod). All of them have `pod-is-complete` set to `false`.

See [find-definitions](#sub-find-definitions) for more information.

#### Array @.refs

It contains all references found in [\$.pod](#pod). All of them have `pod-is-complete` set to `false`.

See [find-references](#sub-find-references) for more information.

#### method human-kind

```perl6
method human-kind (
) return Str
```

Returns the transformation of `$.kind` to a "more understable" version. That means:

- If `$.kind` is equal to `language` then it returns `language documentation`.
- Otherwise, if `@.categories` is equal to `operator` then is set to `@.subkinds operator`. If not, it's set to the result of calling `english-list` with `@.subkinds` or `$.kind` if the previous one is not defined.

Examples:

```
declarator
do (statement prefix)
```

Note: `english-list` is a helper function which join a list using commas and add a final "and" word:

```
my @a = ["a","b","c"];
english-list(@a) # OUTPUT: a, b and c
```

#### method url

```perl6
method url (
) return Str
```

Work in progress :D.

#### method categories

```perl6
method categories (
) return Array
```

Returns `@.categories`. If `@.categories` it's not defined, sets `@.categories` to the same value as `@.subkinds` and returns it.

#### method get-documentables

```perl6
method get-documentables (
) returns Array
```

Returns all [Perl6::Documentable](#perl6documentable) objects (`@.defs`+`@.refs`).

## Perl6::Documentable::Registry

```perl6
    has @.documentables;
    has Bool $.composed = False;
    has %!cache;
    has %!grouped-by;
    has @!kinds;
    has %!routines-by-type;
    has Bool $.verbose;
```

#### @.documentables

If it's not composed, it will contain only [Perl6::Documentable](#perl6documentable) objects with [pod-is-complete](#pod-is-complete) set to `True`, that means, coming from entire pod files. After being composed, it will contain all [Perl6::Documentable](#perl6documentable) objects obtained from processing the previous ones ([@.defs](#defs) and [@.refs](#refs)).

See [processing-pod-source](#sub-processing-pod-source).

#### Bool \$.composed

Boolean indicating if the registry is composed. See [compose](#method-compose).

#### %!cache

This `Hash` object works as a cache for [lookup](#method-lookup) method.

See [lookup](#method-lookup) for more information.

#### %!grouped-by

This `Hash` object works as a cache for [grouped-by](#method-grouped-by) method.

See [grouped-by](#method-grouped-by) for more information.

#### @!kinds

Array containing all different values of `$kinds` found in [@!documentables](#documentables). Set when `compose` is called.

#### \$.tg

Instance of a `Perl6::TypeGraph` object (from this [Perl6::TypeGraph module](https://github.com/antoniogamiz/Perl6-TypeGraph)).

This object is responsible of giving us the correct categories and subkinds of a type. For instance, it sets the category of a type to `domain-specific`, `exception`, etc., which is used in the index generation.

#### %!routines-by-type

Hash object with the following structure:

- `key` => name of the type (filename without the `.pod6` extension)
- `value` => all [Perl6::Documentable](#perl6documentable) objects with `kind` equal to `routine` and the name as the key.

See [compose](#method-compose) to see how it's initialized.

#### Bool \$.verbose

Useful information will be printed if set to `True` (`False` by default).

#### submethod BUILD

```perl6
submethod BUILD (
    Bool :$verbose?,
) returns Perl6::Documentable::Registry
```

In this method the attribute `$.tg` is configured as specified in the [module documentation](https://github.com/antoniogamiz/Perl6-TypeGraph).

If [\$.verbose](#bool-verbose), then useful information will be printed.

### Processing methods

#### method add-new

```perl6
method add-new(
    Perl6::Documentable $d
) return Perl6::Documentable;
```

Adds a new [Perl6::Documentable](#perl6documentable) object to the registry. Returns the same object added.

Example:

```perl6
use Perl6::Documentble::Processing;
use Pod::Load;

my $doc = processing-pod-source (
    pod      => load("pod.pod6"),
    origin   => Perl6::Documentable.new,
    filename => "pod"
);

my $registry = Perl6::Documentable::Registry.new;
$registry.add-new: $doc;
```

#### method compose

```perl6
method compose (
) return Boolean;
```

This methods does several things:

1. Initialize [@!kinds](#kinds) and join all [Perl6::Documentable](#perl6documentable) objects found in every element of [@!documentables](#documentables) (that means all [@.defs](#defs) and [@.refs](#refs) attributes).
2. Compose every [Perl6::Documentable](#perl6documentable) object in [@.documentables](#documentables) with `kind` set to `type`, calling [compose-type](#method-compose-type).
3. `%!routines-by-type` is set, grouping the [Perl6::Documentable](#perl6documentable) collection by `kind="routine"` using [lookup](#method-lookup). Then the result is classified by [name](#name). You may think that after this process, `%!routines-by-type` contains more things, apart from the "routines by type". You are right! But we do not care because we will consult this `Hash` using the names of the types, so we will get what we want anyway.
4. Finally, [\$!composed](#composed) is set to `True` and returns it.

```perl6
use Perl6::Documentable::Processing;

my $registry = process-pod-collectiion(
    :cache,
    :verbose,
    :topdir("doc"),
    :dirs(["Language", "Type", "Programs", "Nativ" ])
);

# once we have processed all the pods we can compose it
$registry.compose;

# now all definitions and references are also available through
# @.documentables (and the original ones too)
say $registry.documentables;
```

#### method compose-type

```perl6
method compose-type (
    Perl6::Documentable $doc
) return Mu;
```

This method is responsible of completing the pod of those [Perl6::Documentable](#perl6documentable) objects with `kind` set to `type`.

This method use the `Perl6::TypeGraph` object stored in `$!tg`, so if a type with the same name as the [Perl6::Documentable](#perl6documentable) object is not found in `$!tg.types`, it will simply return.

Otherwise, three things will be added in this order:

1. A typegraph fragment generated by [typegraph-fragment](#method-typegraph-fragment).
2. All routines from the roles made by the type (using `%!routuines-bytype`, see [compose](#method-compose)).
3. All routines from the class which the type inherits from and the routines of the roles made by those classes (using `%!routuines-bytype`, see [compose](#method-compose)).

#### method typegraph-fragment

```perl6
method typegraph-fragment (
    Str $podname
) return Array[Pod::Block];
```

Given a `$podname` (filename with `.pod6` extension), it returns a pod fragment containing a heading (`"Type Graph"`) and the file `template/tg-fragment.html` correctly initialized.

### Consulting methods

#### method get-kinds

```perl6
method get-kinds(
) return Array
```

Returns an array containing all `kind` values after processing the pod collection. Currently there are only 6 different values: `[language programs type syntax reference routine]`.

#### method grouped-by

```perl6
method grouped-by(
    Str $what
) returns Array[Perl6::Documentable];
```

The first time it is called it initializes a key `$what`, with the result of classifying [@!documentables](#documentables) by `$what`. `$what` needs to be the name of an attribute of a [Perl6::Documentable](#perl6documentable) object: `kind`, for instance.

This result is stored in [%!grouped-by](#grouped-by) so the next time it's called it will be faster.

#### method lookup

```perl6
method lookup(
    Str $what,
    Str $by
) returns Array[Documentable];
```

This method uses [%!cache](#cache), which is a two-layer `Hash` object. That means you first consult it with one key, `$by`, and that returns another `Hash` which is consulted with the key `$what`.

So, `$by` has to be the name of an attribute of [Perl6::Documentable](#perl6documentable) class. Elements in [@!documentables](#documentables) will be classified following that attribute. Then, `$what` must be one of the possible values that the attribute `$by` can take.

In this setting, `lookup` will return the [Perl6::Documentable](#perl6documentable) objects in [@!documentables](#documentables) whose attribute `$by` is equal to `$what`.

This result is stored in [%!cache](#cache) so the next time it's called it will be faster.

```perl6

my $registry = (... initialized previously ...);

# all Perl6::Documentable objects with kind set to type
$registry.lookup("type", :by<kind>)

# all Perl6::Documentable objects with name set to close
$registry.lookup("close", :by<name>)

```

### Indexing methods

All `*-index` methods are used to generate the main index in the doc site ([Language](https://docs.perl6.org/language.html), [Types](https://docs.perl6.org/types.html), ...).

#### method programs-index

```perl6
method programs-index (
) return Array[Hash];
```

It takes all [Perl6::Documentable](#perl6documentable) objects in the [Perl6::Documentable::Registry](#perl6documentableregistry) with `kind` set to `programs`.
After that it makes a `map` and creates the following `Hash` for each one:

```
%(
    name    => ...
    url     => ...
    summary => ...
)
```

Note: `...` means that is the attribute of the [Perl6::Documentable](#perl6documentable).

#### method language-index

```perl6
method language-index (
) return Array[Hash];
```

It takes all [Perl6::Documentable](#perl6documentable) objects in the [Perl6::Documentable::Registry](#perl6documentableregistry) with `kind` set to `language`.
After that it makes a `map` and creates the following `Hash` for each one:

```
%(
    name    => ...
    url     => ...
    summary => ...
)
```

Note: `...` it means that is the attribute of the Documentable.

#### method type-index

```perl6
method type-index (
) return Array[Hash];
```

It takes all [Perl6::Documentable](#perl6documentable) objects in the [Perl6::Documentable::Registry](#perl6documentableregistry) with `kind` set to `type`. After that it makes a `map` and creates the fololwing `Hash` for each one:

```
%(
    name     => ...
    url      => ...
    subkinds => ...
    summary  => ...
    subkind  => first subkind
)
```

Note: `...` means that is the attribute of the Documentable.

#### method type-subindex

```perl6
method type-subindex (
  Str :$category
) return Array[Hash];
```

Same as `type-index` but you can filter by `$category`. You can pass one of the following categories: `<basic composite domain-specific exceptions>`.

#### method routine-index

```perl6
method routine-index (
) return Array;
```

It takes all [Perl6::Documentable](#perl6documentable) objects in the [Perl6::Documentable::Registry](#perl6documentableregistry) with `kind` set to `routine`. After that it makes a `map` and creates the following `Hash` for each one:

```
%(
    name     => ...
    url      => ...
    subkinds => ...
    origins  => $from
)
```

Where `$from` is an array of `[$name, $url]` containing the names and urls of the [Perl6::Documentable](#perl6documentable) objects where the routine was found.

Note: `...` means that is the attribute of the Documentable.

#### method routine-subindex

```perl6
method routine-subindex (
  Str :$category
) return Array[Hash];
```

Same as `routine-index` but you can filter by `$category`. You can pass one of the following categories: `<sub method term operator trait submethod>`.

#### method generate-search-index

```perl6
method generate-search-index (
) return Array[Str];
```

Returns an array whose items are in the following format: `{category: "", value: "", url: ""}`.

This array is initialized calling `lookup` with every possible value of `kind` (see `get-kinds`). `category` is set to `kind` or to `subkind` if `lookup` returns more than one `Documentable` object. `value` is set to the name of the `Documentable` and `url` too.

You can see the current search index [here](https://gist.github.com/antoniogamiz/05971277d081c4806c7cc3867a66b1b4).

## Perl6::Documentable::Processing

This is the module where all processing happens. It takes a pod collection and returns a [Perl6::Documentable::Registry](#perl6documentableregistry) object completely initialized with all the necessary information.

#### sub process-pod-collection

```perl6
sub process-pod-collection (
    Bool       :$cache,
    Bool       :$verbose,
    Str        :$topdir,
    Array[Str] :@dirs
) return Perl6::Documentable::Registry
```

Main function of this module. Process every directory in `@dirs` (with [process-pod-dir](#sub-process-pod-dir)) and add the results to the new [Perl6::Documentable::Registry](#perl6documentableregistry) object.

If `:$cache` is `True`, pods will be extracted from a cache, if possible.

Example:

```perl6
my $registry = process-pod-collection (
    cache => True,
    verbose => True,
    topdir => "doc",
    dirs => ["Language", "Programs", "Type", "Native"]
); # done! now you only need to compose it!
```

#### sub process-pod-dir

```perl6
sub process-pod-dir (
    Str  :$topdir,
    Str  :$dir,
    Sub  :&load = configure-load-function(:!cache),
    Bool :$verbose
) return Array[Perl6::Documentable]
```

Process all pod files in `$topdir/$dir`. Load them with `&load` without using a cache (by default).

It returns an array containing all [Perl6::Documentable] objects (one per file) resulting [process-pod-source](#sub-process-pod-source).

Example:

```perl6
my @documentables = process-pod-dir (
    topdir  => "doc",
    dir     => "Type",
    verbose => False # no output
); # without cache

my @documentables = process-pod-dir (
    topdir  => "doc",
    load    => configure-load-function(:cache),
    dir     => "Type",
    verbose => True   # informative output
); # using cache
```

#### sub process-pod-source

```perl6
sub process-pod-source (
    Str        :$kind,
    Pod::Named :$pod,
    Str        :$filename
) return Perl6::Documentable
```

Given a pod, returns the associated [Perl6::Documentable](#perl6documentable) object, correctly initialized.

How it is initialized?

- `$name` is set to `$filename` by default. If a `=TITLE` element is found, then it is set to its contents. In addition, if `$kind` is `type`, `$name` will be set to the last word of that content.
- `$summary` is set to the content of the first `=SUBTITLE` element.
- `$pod-is-complete` is set to `True` (becuase it's a complete pod).
- `$url` is set to `/$kind/$link`, where `$link` is set to `$filename` if a `link` value is not set in the pod configuration.
- `$kind` and `$subkinds` are set to `$kind`.
- `@.defs` and `@.refs` are set by [find-definitions](#sub-find-definitions) and [find-references](#sub-find-references) respectively.

#### sub parse-definition-header

```perl6
sub parse-definition-header (
    Pod::Heading :$heading
) return Hash
```

This method takes a `Pod::Heading` object and return a non-empty hash if it's a definition. This hash is something like this:

```perl6
%(
    name       => ...
    kind       => ...
    subkinds   => ...
    categories => ...
)
```

The value of these parameters depends on the definition found, these are the four different types you will find:

```perl6
=head2 The <name> <subkind>
Example:
=head2 The C<my> declarator
```

```perl6
=head2 <subkind> <name>
Example:
=head2 sub USAGE
```

```perl6
=head X<<name>|<subkind>>
```

First two types are parsed by [Perl6::Documentable::Processing::Grammar](lib/Perl6/Documentable/Processing/Grammar.pm6) and the last one does not need to be parsed because it will be considered a valid definition no matter what you type inside.

#### sub determine-subkinds

```perl6
sub determine-subkinds (
    Str $name,
    Str $origin-name,
    Str $code
) return Array[Str]
```

This function returns the proper subkinds of a function based on its definition code (the one you find after the `Defined as`).

This is necessary because some functions are declared with several signatures.

#### sub find-definitions

```perl6
sub find-definitions (
    Array                      :$pod,
    Perl6::Documentable        :$origin,
    Int                        :$min-level = -1,
    Array[Perl6::Documentable] :@defs
) return Int
```

This function takes a pod and returns an array of [Perl6::Documentable](#perl6documentable) objects containing all definitions found in the pod (to find valid definitions it uses [parse-definition-header](#sub-parse-definition-header)). It runs through the pod content and looks for valid headings `@defs` is populated recursively.

When we find a new definition, a new [Perl6::Documentable](#perl6documentable) object is created and initialized to:

- `$origin`: to `$origin`.
- `$pod`: It will be populated with the pod section corresponding to the definition and its subdefinitions (all valid headers with a greater level until one with the same or lower level is found).
- `$pod-is-complete`: to `false` beacuse it's a definition.
- `name`, `kind`, `subkinds` and `categories` to the output of [parse-definition-header](#sub-parse-definition-header).

Example:

```perl6
use Pod::Load;

my $pod = load("type/Any.pod6").first;
my $origin = Perl6::Documentable.new(:$pod);

my @documentables;
find-definitions(
    pod => $pod,
    :$origin,
    :defs(@documentables)
)

# this array contains all definitions found
say @documentables;
```

#### sub find-references

```perl6
sub find-references (
    Array                      :$pod,
    Str                        :$url,
    Perl6::Documentable        :$origin,
    Array[Perl6::Documentable] :@refs
) return Mu
```

Quite similar to [find-definitions](#sub-find-definitions). It runs through the entire pod looking for all `X<>` elements.

It goes through all the pod tree recursively searching for `X<>` elements (`Pod::FormattingCode`). When one is found, `register-reference` is called with the pod fragment associated to that element, the same origin and the associated url:

```
$url ~ '#' ~ index-entry-$pod.meta-$index-text
```

#### sub create-references

```perl6
sub create-references (
    Pod::FormatingCode  :$pod,
    Perl6::Documentable :$origin,
    Str                 :$url
) return Array[Perl6::Documentable]
```

Every time it's called it creates a [Perl6::Documentable](#perl6documentable) object, with `$kind` and `$subkinds` set to references. `name` is taken from the meta part: the last element becomes the first and the rest are written right after.

Example:

```
Given the meta ["some", "reference"], the name would be: "reference (some)"
```

That's done for every element in meta, that means, if meta has 2 elements, then 2 [Perl6::Documentable](#perl6documentable) objetcs will be added (you can specify several elements in a `X<>` using `;`).

If there is no meta part, then the pod content is taken as name.

## Perl6::Documentable::To::HTML

#### sub header-html

```perl6
sub header-html (
    Str $current-selection,
    Str $pod-path
) return Str;
```

Returns the HTML header for every page. `$current-selection` has to be set to one element of the menu. If that element has a submenu, it will be created too.

`$pod-path` is the path relative to `doc` with the extension `.pod6`. Used in the edit buttom url.

#### sub footer-html

```perl6
sub footer-html (
    Str $pod-path
) return Str;
```

Returns the HTML footer for every page. `$pod-path` is the path relative to `doc` with the extension `.pod6`. Used to the edit buttom url.

#### sub \*-index-html

```perl6
sub *-index-html (
    Array[Hash] @index
) return Str
```

Takes the index generated the [Perl6::Documentable::Registry](#perl6documentableregistry) and return its HTML version.

Notes: in `language-index-html` you have and additional parameter:

```perl6
sub *-index-html (
    Array[Hash] @index,
    Bool        $manage = False
) return Str
```

This parameter is used to sort the index elements in a certain way (following the configuration file [language-order-control.json](resources/language-order-control.json)).

## Perl6::Utils

Some auxiliar functions to ease the job.

#### sub recursive-dir

```perl6
sub recursive-dir (
    Str :$dir
) return Array;
```

This function returns a List of IO objects. Each IO object is one file in `$dir`.

#### sub get-pod-names

```perl6
sub get-pod-names (
    Str :$topdir
    Str :$dir
) return Array;
```

What does the following array look like? An array of sorted pairs

- the sort key defaults to the base filename stripped of '.pod6'.
- any other sort order has to be processed separately as in 'Language'.

The sorted pairs (regardless of how they are sorted) must consist of:

- key: base filename stripped of its ending .pod6
- value: filename relative to the "$topdir/$dir" directory

#### sub pod-path-from-url

```perl6
sub pod-path-from-url (
    Str $url
) return Str;
```

Determine the path to source POD from the POD object's url attribute.

#### sub svg-for-file

```perl6
sub svg-for-file (
    Str $file
) return Str;
```

Return the SVG for the given file, without its XML header

For instance, given: `t/html/basic.svg`, it will return `t/html/basic-without-xml.svg`.

#### URL logic

This one is quite a mess, it will be a todo for now.

## Resources

### Templates

#### [head.html](template/head.html)

Some meta info and stylesheet for every page in the doc site.

#### [header.html](template/header.html)

Header of every HTML page in the doc site. `MENU` will be replaced by `Perl6::Documentable::To::HTML` with the
generated menu.

#### [footer.html](template/footer.html)

Footer for every page in the site. `SOURCEURL`, `SOURCECOMMIT` and `DATETIME` will be replaced by `Perl6::Documentable::To::HTML`.

#### [tg-fragment.html](template/tg-fragment.html)

Used by [typegrah-fragment](#method-typegraph-fragment).

#### [search_template.js](template/search_template.js)

Search funtion for the doc site. It uses [Sift 4](https://siderite.blogspot.com/2014/11/super-fast-and-accurate-string-distance.html) algorithm for strings comparison.

### HTML

In this directory you can find the CSS files used by the site, the images (graphs generated by `Perl6::TypeGraph`) will be here too. All HTML generated files will be also stored in here.

In addition, there is a `.htaccess` file used by the server (#TODO: document it).

## Tests

Test files follow this convention:

- From 0 to 99: basic tests, not related with the core functionality of the module.
- From 100-199: `Perl6::Utils` related tests.
- From 200 to 299: [Perl6::Documentable](#perl6documentable) related tests.
- From 300 to 399: [Perl6::Documentable::Registry](#perl6documentableregistry) related tests.
- From 400 to 499: `Perl6::Documentable::Registry::To::HTML` related tests.

# AUTHORS

Moritz Lenz <@moritz>

Jonathan Worthington <@jnthn>

Richard <@finanalyst>

Will Coleda <@coke>

Aleks-Daniel <@AlexDaniel>

Sam S <@smls>

Alexander Moquin <@Mouq>

Antonio <antoniogamiz10@gmail.com>

# COPYRIGHT AND LICENSE

Copyright 2019 Perl6 Team

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

```

```
