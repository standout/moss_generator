# frozen_string_literal: true

require 'moss_generator/vat_rate'
require 'json'

RSpec.describe MossGenerator::VatRate do
  let(:vat_rates) { JSON.parse(File.read('spec/fixtures/vat_rates.json')) }

  describe '.for' do
    subject(:for) { described_class.for(country_code) }

    before { stub_vat_rates_file }

    context 'when country code is SE' do
      let(:country_code) { 'SE' }

      it { is_expected.to eq(25) }
    end

    context 'when country code is FR' do
      let(:country_code) { 'FR' }

      it { is_expected.to eq(20) }
    end
  end

  def stub_vat_rates_file
    allow(MossGenerator::VatRate).to receive(:vat_rates).and_return(vat_rates)
  end
end
