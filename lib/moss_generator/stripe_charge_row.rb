# frozen_string_literal: true

require 'moss_generator/vat_rate'

module MossGenerator
  # Fetches charge data from single Stripe charge
  class StripeChargeRow
    class NoConsumptionCountryError < StandardError; end

    attr_reader :charge

    def initialize(charge)
      @charge = charge
    end

    def country_code
      return fetch_country_code unless fetch_country_code.nil?

      raise NoConsumptionCountryError, "charge: #{charge}"
    end

    # Integer
    #
    # Returns the amount with fee reductions
    def amount
      charge.dig('balance_transaction', 'net')
    end

    def vat_rate
      MossGenerator::VatRate.for(country_code)
    end

    def vat_amount
      amount * vat_rate_calculatable_percent
    end

    private

    def vat_rate_calculatable_percent
      (vat_rate.to_f / 100)
    end

    def fetch_country_code
      charge.dig('payment_method_details', 'card', 'country') ||
        charge.dig('billing_details', 'address', 'country')
    end
  end
end
