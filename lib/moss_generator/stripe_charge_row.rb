# frozen_string_literal: true

require 'moss_generator/vat_rate'
require 'money'
require 'valvat'
require 'countries'

module MossGenerator
  # Parse charge data from single Stripe charge
  class StripeChargeRow
    class NoConsumptionCountryError < StandardError; end

    class NoVatRateForCountryError < StandardError; end

    class NoExchangeRateForCurrencyOrDateError < StandardError; end

    attr_reader :charge, :rates, :vat_rate_service

    def initialize(charge, rates, vat_rate_service = MossGenerator::VatRate)
      @charge = charge
      @rates = rates
      @vat_rate_service = vat_rate_service
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
      @vat_rate = special_vat_rate_for_2021_quarter_one
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

    def special_vat_rate_for_2021_quarter_one
      if fetch_country_code.casecmp?('IE')
        changeover_day = Date.parse('2021-03-01').to_time
        return 23 if Time.at(charge['created']) >= changeover_day

        21
      else
        vat_rate_service.for(country_code)
      end
    end

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
      source_country || payment_method_country || fallback_country
    end

    def source_country
      return source_owner_country if source_type.nil?

      charge.dig('source', source_type, 'country') ||
        charge.dig('source', source_type, 'address_country')
    end

    def payment_method_country
      return if payment_type.nil?

      charge.dig('payment_method_details', payment_type, 'country') ||
        charge.dig('payment_method_details', payment_type, 'address_country')
    end

    def source_type
      charge.dig('source', 'type') || charge.dig('source', 'object')
    end

    def source_owner_country
      charge.dig('source', 'owner', 'address', 'country')
    end

    def payment_type
      charge.dig('payment_method_details', 'type')
    end

    def fallback_country
      charge.dig('shipping', 'address', 'country')
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
