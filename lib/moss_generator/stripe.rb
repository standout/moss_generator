# frozen_string_literal: true

require 'csv'
require 'moss_generator/stripe_charge_row'

module MossGenerator
  # Generate MOSS CSV string from Stripe charges
  class Stripe
    class NoTurnoverCountryError < StandardError; end

    attr_reader :charges, :vat_number, :period, :year

    def initialize(charges, vat_number, period, year)
      @charges = charges
      @vat_number = vat_number
      @period = period
      @year = year
    end

    def self.call(charges, vat_number, period, year)
      new(charges, vat_number, period, year).call
    end

    def call
      CSV.generate(csv_options) do |csv|
        csv << first_row
        csv << second_row
        generate_charges_rows(csv)
      end
    end

    private

    def first_row
      ['MOSS_001']
    end

    def second_row
      [vat_number, period, year]
    end

    def generate_charges_rows(csv)
      build_charges_rows.each { |row| csv << row }
    end

    def group_charges_rows
      charges_rows = charges.map do |charge|
        charge_row = MossGenerator::StripeChargeRow.new(charge)
        next if charge_row.skippable?

        charge_row
      end.compact
      charges_rows.group_by(&:country_code)
    end

    def build_charges_rows
      group_charges_rows.map do |country, charges|
        next if country == 'SE' && turnover_country == 'SE'
        next if charges.first.vat_rate.nil?

        country_row(country, charges)
      end.compact
    end

    def country_row(country, charges)
      [turnover_country,
       country,
       format_to_two_decimals(charges.first.vat_rate),
       format_to_two_decimals(charges.sum(&:amount)),
       format_to_two_decimals(charges.sum(&:vat_amount))]
    end

    def csv_options
      { col_sep: column_separator, row_sep: row_separator }
    end

    def row_separator
      ";\r\n"
    end

    def column_separator
      ';'
    end

    def format_to_two_decimals(number)
      format('%.2f', number).sub('.', ',')
    end

    # vat_numbers first two characters shall contain the country code
    def turnover_country
      country_code = vat_number[0...2]
      if country_code.nil?
        raise NoTurnoverCountryError,
              "vat_number: #{vat_number}"
      end
      return country_code if country_code == 'SE'

      vat_number
    end
  end
end
