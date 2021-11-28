AnyStyle
========
[![Build Status](https://travis-ci.org/inukshuk/anystyle.svg?branch=master)](https://travis-ci.org/inukshuk/anystyle)
[![Coverage Status](https://coveralls.io/repos/github/inukshuk/anystyle/badge.svg?branch=master)](https://coveralls.io/github/inukshuk/anystyle?branch=master)

AnyStyle is a very fast and smart parser for academic references. It
was originally inspired by [ParsCit](http://aye.comp.nus.edu.sg/parsCit/)
and [FreeCite](http://freecite.library.brown.edu/); AnyStyle uses machine
learning algorithms and aims to make it easy to train the model with data
that is relevant to your parsing needs.


Using AnyStyle CLI
------------------

    $ [sudo] gem install anystyle-cli
    $ anystyle --help
    $ anystyle help find
    $ anystyle help parse

See [anystyle-cli](https://github.com/inukshuk/anystyle-cli) for more details.

Using AnyStyle in Ruby
----------------------
Install the `anystyle` gem.

    $ [sudo] gem install anystyle

Once installed, you can use the static Parser and Finder instances
by calling the `AnyStyle.parse` or `AnyStyle.find` methods. For example:

```ruby
require 'anystyle'

pp AnyStyle.parse 'Derrida, J. (1967). L’écriture et la différence (1 éd.). Paris: Éditions du Seuil.'
#-> [{
#  :author=>[{:family=>"Derrida", :given=>"J."}],
#  :date=>["1967"],
#  :title=>["L’écriture et la différence"],
#  :edition=>["1"],
#  :location=>["Paris"],
#  :publisher=>["Éditions du Seuil"],
#  :language=>"fr",
#  :scripts=>["Common", "Latin"],
#  :type=>"book"
#}]
```

Alternatively, you can create your own `AnyStyle::Parser` or
`AnyStyle::Finder` with custom options.


Using the AnyStyle Web App
--------------------------
AnyStyle is available as web application at [anystyle.io](https://anystyle.io).

The web application [is open source](https://github.com/inukshuk/anystyle.io)
and you can also host yourself!

Improving results for your data
=================================

Training
--------
You can train custom Finder and Parser models. To do this, you need
to prepare your own data sets for training. You can create your own
data from scratch or build on AnyStyle's default sets. The default
parser model is based on the
[core](https://github.com/inukshuk/anystyle/blob/master/res/parser/core.xml)
data set; the default finder model source data is not publicly
available in its entirety, but you can find a number of tagged
documents
[here](https://github.com/inukshuk/anystyle/blob/master/res/finder).

When you have compiled a data set for training, you will be ready
to create your own model:

    $ anystyle train training-data.xml custom.mod

This will save your new model as `custom.mod`. To use your model
instead of AnyStyle's default, use the `-P` or `--parser-model` flag
and, respectively, `-F` or `--finder-model` to use a custom Finder
model. For instance, the command below would parse all references
in `bib.txt` using the custom model we just trained and print the
result to STDOUT using the JSON output format:

    $ anystyle -P custom.mod -f json parse bib.txt -

When training your own models, it is good practice to check the
quality using a second data set. For example, using AnyStyle's own
[gold](https://github.com/inukshuk/anystyle/blob/master/res/parser/gold.xml)
data set (a large, manually curated data set) we could check our
custom model like this:

    $ anystyle -P x.mod check ./res/parser/gold.xml
    Checking gold.xml.................   1 seq  0.06%   3 tok  0.01%  3s

This command will print the sequence and token error rates; in
the case of AnyStyle a the number of sequence errors is the number
of references which were tagged differently by the parser than they
were in the input; the number of token errors is the total number of
words across all the references which were tagged differently. In the
example above, we got one reference wrong (out of 1700 at the time);
but even this one reference was mostly tagged correctly, because only
a total of 3 words were tagged differently.

When working with training data, it is a good idea to use the
`Wapiti::Dataset` API in Ruby: it supports all the standard set
operators and makes it very easy to combine or compare data sets.

Natural Languages used in AnyStyle
----------------------------------

As mentioned above, the
[core](https://github.com/inukshuk/anystyle/blob/master/res/parser/core.xml)
dataset contains the manually marked-up references that are used as the
basis for the default AnyStyle parsing model. If the references you are
trying to parse include many non-English documents, the distribution of
natural languages in this corpus is relevant (detected using [cld](https://github.com/jtoy/cld)).

| Language                | n   |
|-------------------------|-----|
| ENGLISH                 | 965 |
| FRENCH                  | 54  |
| GERMAN                  | 26  |
| ITALIAN                 | 11  |
| Others                  | 9   |
|                         |     |
| Not reliably determined | 449 |
| (but mainly English)    |     |

(These data are based on AnyStyle version 1.3.13) 

There is a strong prevalence of English-language documents with the
conventions used in English-language bibliographies, with some
representation of other European languages. The languages used reflect
those used in scientific publishing as well as the maintainers'
competencies. If you are working with many documents in languages other
than English, you might consider training the model with some examples
in the relevant languages.

AnyStyle should work with references written in any Latin script
(including most European languages, languages such as Indonesian and
Malaysian, as well as romanised Arabic, Chinese and Japanese). It should
also support languages written with non-Latin alphabets (such as
Russian), although no examples of these appear in the default training
sets. Languages written in syllabaries or complex symbols which do not
use white space to separate tokens are not compatible with AnyStyle's
approach: this includes Chinese, Japanese, Arabic as well as many Indian
languages. 

Dictionary Adapters
-------------------
During the statistical analysis of reference strings, AnyStyle relies
on a large feature dictionary; by default, AnyStyle creates a persistent
Ruby Hash in the folder of the `anystyle-data` Gem. This uses up about
2MB of disk space and keeps the entire dictionary in memory. If you prefer
a smaller memory footprint, you can alternatively use AnyStyle's GDBM
dictionary. GDBM bindings are part of the Ruby standard library and are
supported on all platforms, but you may have to install GDBM on your
platform before installing Ruby.

If you do not want to use the the persistent Ruyb Hash nor the GBDM
bindings, you can store your dictionary in memory (not recommended) or
use a Redis. The best way to change the default dictionary adapter is by
adjusting AnyStyle's default configuration (when using the default parser
instances you must set the default before using the parser):

    AnyStyle::Dictionary.defaults[:adapter] = :ruby
    #-> Use a persistent Ruby hash;
    #-> slower start-up than GDBM but no extra dependency

    AnyStyle::Dictionary.defaults[:adapter] = :hash
    #-> Use in-memory dictionary; slow start-up but uses no space on disk

    require 'anystyle/dictionary/gdbm'
    AnyStyle::Dictionary.defaults[:adapter] = :gdbm

To use Redis, install the `redis` and `redis/namespace` (optional) Gems
and configure AnyStyle to use the Redis adapter:

    AnyStyle::Dictionary.defaults[:adapter] = :redis

    # Adjust the Redis-specifi configuration
    require 'anystyle/dictionary/redis'
    AnyStyle::Dictionary::Redis.defaults[:host] = 'localhost'
    AnyStyle::Dictionary::Redis.defaults[:port] = 6379

About AnyStyle
==============
Contributing
------------
The AnyStyle source code is
[hosted on GitHub](https://github.com/inukshuk/anystyle/).
You can check out a copy of the latest code using Git:

    $ git clone https://github.com/inukshuk/anystyle.git

If you've found a bug or have a question, please open an issue on the
[AnyStyle issue tracker](https://github.com/inukshuk/anystyle/issues).
Or, for extra credit, clone the AnyStyle repository, write a failing
example, fix the bug and submit a pull request.

Credits
-------
AnyStyle is a volunteer effort and we encourage you
to join us! Over the years our main contributors have been:

* [Alex Fenton](https://github.com/a-fent)
* [Sylvester Keil](https://github.com/inukshuk)
* [Johannes Krtek](https://github.com/flachware)
* [Ilja Srna](https://github.com/namyra)

License
-------
Copyright 2011-2020 Sylvester Keil. All rights reserved.

AnyStyle is distributed under a BSD-style license.
See LICENSE for details.
