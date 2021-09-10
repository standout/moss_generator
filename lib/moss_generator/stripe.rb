# frozen_string_literal: true

require 'csv'
require 'moss_generator/stripe_charge_row'

module MossGenerator
  # Generate MOSS CSV string from Stripe charges
  class Stripe
    class NoTurnoverCountryError < StandardError; end

    attr_reader :charges, :vat_number, :period, :year, :rates, :sale_type

    def initialize(charges, vat_number, period, year, rates, sale_type)
      @charges = charges
      @vat_number = vat_number
      @period = period
      @year = year
      @rates = rates
      @sale_type = sale_type
    end

    def self.call(charges, vat_number, period, year, rates, sale_type)
      new(charges, vat_number, period, year, rates, sale_type).call
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
      ['OSS_001']
    end

    def second_row
      [vat_number, period, year]
    end

    def generate_charges_rows(csv)
      build_charges_rows.each { |row| csv << row }
    end

    def group_charges_rows
      charges_rows = charges.map do |charge|
        charge_row = MossGenerator::StripeChargeRow.new(charge, rates)
        next if charge_row.skippable?

        charge_row
      end.compact
      charges_rows.group_by do |row|
        [row.country_code, row.vat_rate]
      end
    end

    def build_charges_rows
      group_charges_rows.map do |(country, vat), charges|
        next if country == 'SE' && turnover_country == 'SE'
        next if vat.nil?

        country_row(country, charges, vat)
      end.compact
    end

    def country_row(country, charges, vat)
      [turnover_country,
       country,
       format_to_two_decimals(vat),
       format_to_two_decimals(charges.sum(&:amount_without_vat)),
       format_to_two_decimals(charges.sum(&:vat_amount)),
       sale_type]
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
