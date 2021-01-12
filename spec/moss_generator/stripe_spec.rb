# frozen_string_literal: true

require 'moss_generator/stripe'
require 'json'

RSpec.describe MossGenerator::Stripe do
  let(:charges) { JSON.parse(File.read('spec/fixtures/stripe_charges.json')) }

  describe '.call' do
    subject(:call) { described_class.call(charges, 'SE556000016701', 3, 2020) }

    it 'returns a csv format string' do
      result = "MOSS_001;\r\n"\
               "SE556000016701;3;2020;\r\n"\
               "SE;IT;22,00;248687,00;54711,14;\r\n"\
               "SE;FR;20,00;495682,00;99136,40;\r\n"

      expect(call).to eq(result)
    end
  end
end
