# frozen_string_literal: true

require 'moss_generator/vat_rate'
require 'money'
require 'valvat/local'
require 'countries'

module MossGenerator
  # Parse charge data from single Stripe charge
  class StripeChargeRow
    class NoConsumptionCountryError < StandardError; end

    class NoVatRateForCountryError < StandardError; end

    class NoExchangeRateForCurrencyOrDateError < StandardError; end

    attr_reader :charge, :rates

    def initialize(charge, rates)
      @charge = charge
      @rates = rates
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
      not_completed? ||
        company? ||
        fetch_country_code.nil? ||
        sold_outside_of_eu? ||
        swedish_charge? ||
        refunded?
    end

    private

    def company?
      return false if charge.dig('metadata', 'vat_number').nil?

      Valvat::Syntax.validate(charge.dig('metadata', 'vat_number'))
    end

    def sold_outside_of_eu?
      ISO3166::Country.new(fetch_country_code).in_eu? ? false : true
    end

    def swedish_charge?
      fetch_country_code.casecmp?('SE')
    end

    def not_completed?
      charge['status'] != 'succeeded'
    end

    def refunded?
      charge['refunded']
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

    def amount_with_vat
      return if skippable?
      return charge['amount'] if charge['currency'].casecmp?('eur')

      exchanged_amount = calculate_amount_from_rate
      return exchanged_amount unless exchanged_amount.nil?

      raise NoExchangeRateForCurrencyOrDateError, "charge: #{charge}"
    end

    def calculate_amount_from_rate
      # Have to reverse the rate. The base rate is in EUR, so if we have a rate
      # to SEK, the rate will represent the rate from EUR to SEK, but we need
      # the other way around.
      date = Time.at(charge['created']).to_date.to_s
      currency = charge['currency'].upcase
      rate = rates.dig(date, currency)
      return if rate.nil?

      reversed_rate = 1 / rate
      charge['amount'] * reversed_rate
    end
  end
end
