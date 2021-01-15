# frozen_string_literal: true

require 'moss_generator/vat_rate'

module MossGenerator
  # Parse charge data from single Stripe charge
  class StripeChargeRow
    class NoConsumptionCountryError < StandardError; end

    class NoVatRateForCountryError < StandardError; end

    attr_reader :charge

    def initialize(charge)
      @charge = charge
    end

    def country_code
      return fetch_country_code unless fetch_country_code.nil?

      raise NoConsumptionCountryError, "charge: #{charge}"
    end

    def amount
      amount_without_vat
    end

    def vat_rate
      @vat_rate = MossGenerator::VatRate.for(country_code)
    end

    def vat_amount
      amount * vat_rate_calculatable_percent
    end

    private

    def amount_without_vat
      amount_with_vat * percent_without_vat
    end

    def amount_with_vat
      charge.dig('balance_transaction', 'amount')
    end

    def percent_without_vat
      1 / (vat_rate_calculatable_percent + 1)
    end

    def vat_rate_calculatable_percent
      (vat_rate.to_f / 100)
    end

    def fetch_country_code
      charge.dig('payment_method_details', 'card', 'country')
    end
  end
end
