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
                           read_exchange_rates,
                           'GOODS')
    end

    before { stub_vat_rates_file }

    it 'returns a csv format string' do
      result = "OSS_001;\r\n"\
               "SE556000016701;3;2020;\r\n"\
               "SE;IT;22,00;205,90;45,30;GOODS;\r\n"\
               "SE;FR;20,00;415,00;83,00;GOODS;\r\n"\

      expect(call).to eq(result)
    end

    context 'when country is greece (GR)' do
      let(:charges) do
        JSON.parse(File.read('spec/fixtures/stripe_charges_from_greece.json'))
      end

      it 'returns a csv format string with country code EL' do
        result = "OSS_001;\r\n"\
                 "SE556000016701;3;2020;\r\n"\
                 "SE;EL;24,00;202,58;48,62;GOODS;\r\n"\

        expect(call).to eq(result)
      end
    end

    context 'with special_vat_rate_for_2021_quarter_one' do
      subject { true }

      let(:charges) { JSON.parse(File.read(special_path)) }
      let(:special_path) do
        'spec/fixtures/stripe_charges_special_vat_rate_2021_quarter_one.json'
      end

      it 'returns a csv with same country with different vat on two rows' do
        result = "OSS_001;\r\n"\
                 "SE556000016701;3;2020;\r\n"\
                 "SE;IE;23,00;204,23;46,97;GOODS;\r\n"\
                 "SE;IE;21,00;205,79;43,22;GOODS;\r\n"\

        expect(call).to eq(result)
      end
    end
  end
end
