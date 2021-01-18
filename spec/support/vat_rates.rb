# frozen_string_literal: true

require 'moss_generator/vat_rate'
require 'json'

def stub_vat_rates_file
  vat_rates = JSON.parse(File.read('spec/fixtures/vat_rates.json'))
  allow(MossGenerator::VatRate).to receive(:vat_rates).and_return(vat_rates)
end
