# frozen_string_literal: true

require 'json'

module MossGenerator
  # Returns standard vat rate from vat_rates.json
  class VatRate
    class << self
      def for(country_code)
        vat_rates.dig(country_code, 'standard_rate')
      end

      private

      def vat_rates
        JSON.parse(File.read(vat_rates_path))
      end

      def vat_rates_path
        'config/vat_rates.json'
      end
    end
  end
end
