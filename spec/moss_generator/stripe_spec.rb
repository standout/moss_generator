# frozen_string_literal: true

require 'moss_generator/stripe'
require 'json'

RSpec.describe MossGenerator::Stripe do
  let(:charges) { JSON.parse(File.read('spec/fixtures/stripe_charges.json')) }

  describe '.call' do
    subject(:call) do
      described_class.call(charges,
                           'SE556000016701',
                           3,
                           2020,
                           read_exchange_rates)
    end

    before { stub_vat_rates_file }

    it 'returns a csv format string' do
      result = "MOSS_001;\r\n"\
               "SE556000016701;3;2020;\r\n"\
               "SE;IT;22,00;205,90;45,30;\r\n"\
               "SE;FR;20,00;415,00;83,00;\r\n"\

      expect(call).to eq(result)
    end

    context 'with special_vat_rate_for_2021_quarter_one' do
      subject { true }

      let(:charges) { JSON.parse(File.read(special_path)) }
      let(:special_path) do
        'spec/fixtures/stripe_charges_special_vat_rate_2021_quarter_one.json'
      end

      it 'returns a csv with same country with different vat on two rows' do
        result = "MOSS_001;\r\n"\
                 "SE556000016701;3;2020;\r\n"\
                 "SE;IE;23,00;204,23;46,97;\r\n"\
                 "SE;IE;21,00;205,79;43,22;\r\n"\

        expect(call).to eq(result)
      end
    end
  end
end
