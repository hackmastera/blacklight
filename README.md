# Blacklight

[![Build Status](https://travis-ci.org/projectblacklight/blacklight.png?branch=master)](https://travis-ci.org/projectblacklight/blacklight) [![Gem Version](https://badge.fury.io/rb/blacklight.png)](http://badge.fury.io/rb/blacklight) [![Coverage Status](https://coveralls.io/repos/github/projectblacklight/blacklight/badge.svg?branch=master)](https://coveralls.io/github/projectblacklight/blacklight?branch=master)

Blacklight is an open source Solr user interface discovery platform.
You can use Blacklight to enable searching and browsing of your collections.
Blacklight uses the [Apache Solr](http://lucene.apache.org/solr) search engine
to search full text and/or metadata.  Blacklight has a highly
configurable Ruby on Rails front-end. Blacklight was originally developed at
the University of Virginia Library and is made public under an Apache 2.0 license.

## Installation

Add Blacklight to your `Gemfile`:

```ruby
gem "blacklight"
```

Run the install generator which will copy over some initial templates, migrations, routes, and configuration:

```bash
rails generate blacklight:install
```


## Documentation, Information and Support

* [Project Homepage](http://projectblacklight.org)
* [Developer Documentation](https://github.com/projectblacklight/blacklight/wiki)
* [Quickstart Guide](https://github.com/projectblacklight/blacklight/wiki/Quickstart)
* [Issue Tracker](https://github.com/projectblacklight/blacklight/issues)
* [Support](https://github.com/projectblacklight/blacklight/wiki/Support)

## Dependencies

* Ruby 2.1+
* Bundler
* Rails 5.0+

## Configuring Apache Solr
You'll also want some information about how Blacklight expects [Apache Solr](http://lucene.apache.org/solr ) to run, which you can find in [README_SOLR](https://github.com/projectblacklight/blacklight/wiki/README_SOLR)

## Building the javascript
The javascript is built by npm from sources in `app/javascript` into a bundle
in `app/assets/javascripts/blacklight/blacklight.js`. This file should not be edited
by hand as any changes would be overwritten.

This is accomplished with the following steps:
1. Install npm
1. run `npm install` to download dependencies
1. run `npm run-script js-compile-bundle` to build the bundle
1. run `npm publish` to push the javascript package to https://npmjs.org/package/blacklight-frontend

## Using the javascript
Install Webpacker
Add blacklight-frontend as a dependency by doing:
```
yarn add blacklight-frontend
```

\* maybe we need to satisfy the popper dependency too?

Then add these lines to `config/webpack/environment.js` as per https://getbootstrap.com/docs/4.0/getting-started/webpack/
and https://github.com/rails/webpacker/blob/master/docs/webpack.md#plugins

```js
const webpack = require('webpack')

environment.plugins.set(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default'],
  })
)

module.exports = environment
```

In you pack file (`app/javascript/packs/application.js`), require blacklight:
```
require('blacklight-frontend/app/assets/javascripts/blacklight/blacklight')
```
Then remove these requires from `app/assets/javascripts/application.js`:

```
//= require jquery
//= require popper
//= require twitter/typeahead
//= require bootstrap
```

Add the following to the app/views/layouts/blacklight/base.html.erb (maybe this can be simpler)
```
<%= javascript_pack_tag 'application' %>
```
You can probably remove the `<%= javascript_include_tag %>`

### Using sprockets (not webpacker)

If you want to use sprockets rather than webpacker, you must ensure these dependencies are in your Gemfile (done automatically by the install generator):

```
gem 'bootstrap', '>= 4.0.0.beta', "< 5"
gem 'popper_js'
gem 'twitter-typeahead-rails'
```

Then insure these requires are in `app/assets/javascripts/application.js`  (done automatically by the install generator):

```
//= require jquery
//= require popper
//= require twitter/typeahead
//= require bootstrap
```
