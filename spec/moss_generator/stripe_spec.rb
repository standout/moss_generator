# frozen_string_literal: true

require 'moss_generator/stripe'
require 'json'

RSpec.describe MossGenerator::Stripe do
  let(:charges) { JSON.parse(File.read('spec/fixtures/stripe_charges.json')) }
  let(:vat_rate_service) { MossGenerator::VatRate }

  describe '.call' do
    subject(:call) do
      described_class.call(charges,
                           'SE556000016701',
                           3,
                           2020,
                           read_exchange_rates,
                           'GOODS',
                           vat_rate_service)
    end

    before { stub_vat_rates_file }

    it 'returns a csv format string' do
      result = "OSS_001;\r\n"\
               "SE556000016701;3;2020;\r\n"\
               "SE;IT;22,00;205,90;45,30;GOODS;\r\n"\
               "SE;FR;20,00;415,00;83,00;GOODS;\r\n"\

      expect(call).to eq(result)
    end

    context 'with custom VAT rate service' do
      let(:vat_rate_service) do
        service = Class.new do
          def for(country_code)
            {
              'IT' => 3.12,
              'FR' => 32
            }.fetch(country_code)
          end
        end

        service.new
      end

      it 'returns a csv with VAT rates from service' do
        result = "OSS_001;\r\n"\
                 "SE556000016701;3;2020;\r\n"\
                 "SE;IT;3,12;243,60;7,60;GOODS;\r\n"\
                 "SE;FR;32,00;377,28;120,72;GOODS;\r\n"\

        expect(call).to eq(result)
      end
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
