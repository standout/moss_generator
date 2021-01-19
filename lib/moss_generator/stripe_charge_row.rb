# frozen_string_literal: true

require 'moss_generator/vat_rate'
require 'money'
require 'valvat/local'

module MossGenerator
  # Parse charge data from single Stripe charge
  class StripeChargeRow
    class NoConsumptionCountryError < StandardError; end

    class NoVatRateForCountryError < StandardError; end

    class NotInEuroError < StandardError; end

    attr_reader :charge

    def initialize(charge)
      @charge = charge
    end

    def country_code
      return fetch_country_code unless fetch_country_code.nil?

      raise NoConsumptionCountryError, "charge: #{charge}"
    end

    def amount_without_vat
      Money.new(amount_with_vat * percent_without_vat).dollars.to_f
    end

    def amount_without_vat_cents
      Money.new(amount_with_vat * percent_without_vat).cents
    end

    def vat_rate
      @vat_rate = MossGenerator::VatRate.for(country_code)
    end

    def vat_amount
      Money.new(amount_without_vat_cents * vat_rate_calculatable_percent)
           .dollars
           .to_f
    end

    def skippable?
      company? || not_completed? || refunded?
    end

    private

    def company?
      return false if charge.dig('metadata', 'vat_number').nil?

      Valvat::Syntax.validate(charge.dig('metadata', 'vat_number'))
    end

    def not_completed?
      charge['status'] != 'succeeded'
    end

    def refunded?
      charge['refunded']
    end

    def amount_with_vat
      return charge['amount'] if charge['currency'].casecmp?('eur')

      raise NotInEuroError, "charge: #{charge}"
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
