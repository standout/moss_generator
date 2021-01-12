# MossGenerator

Generate CSV-formatted string from specified data to be able to create a [MOSS (Mini One Stop Shop)](https://www.skatteverket.se/foretagochorganisationer/moms/deklareramoms/mossredovisningavmomspadigitalatjanster.4.3aa8c78a1466c5845876a05.html) file for Skatteverket.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'moss_generator'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install moss_generator

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Vat Rates

```
* Current Vat rates fetched at 2021/01/11
* Vat rates in spec file from 2021/01/11
```


Vat rates currently needs to be updated manually in `config/vat_rates.json`.
[VatLayer](https://vatlayer.com) has a nice API one could use (100 requests for free each month) to make this process automatic. Until then, do a request through their api and copy JSON-response to file and remove status from response.

Rates can also be found on the official website of the European Union [https://europa.eu/youreurope/business/taxation/vat/vat-rules-rates/index_en.htm#shortcut-8](https://europa.eu/youreurope/business/taxation/vat/vat-rules-rates/index_en.htm#shortcut-8), updates two times a year.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/standout/moss_generator.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
