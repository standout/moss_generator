# frozen_string_literal: true

require 'moss_generator/stripe'
require 'json'

RSpec.describe MossGenerator::Stripe do
  let(:charges) { JSON.parse(File.read('spec/fixtures/stripe_charges.json')) }

  describe '.call' do
    subject(:call) { described_class.call(charges, 'SE556000016701', 3, 2020) }

    before { stub_vat_rates_file }

    it 'returns a csv format string' do
      result = "MOSS_001;\r\n"\
               "SE556000016701;3;2020;\r\n"\
               "SE;IT;22,00;205,90;45,30;\r\n"\
               "SE;FR;20,00;415,00;83,00;\r\n"\

      expect(call).to eq(result)
    end
  end
end
