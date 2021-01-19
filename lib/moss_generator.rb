# frozen_string_literal: true

require_relative 'moss_generator/version'
require_relative 'moss_generator/vat_rate'
require_relative 'moss_generator/stripe'

# Generate CSV-formatted string for MOSS report
module MossGenerator
  Money.default_currency = Money::Currency.new('EUR')
  Money.rounding_mode = BigDecimal::ROUND_HALF_UP
end
