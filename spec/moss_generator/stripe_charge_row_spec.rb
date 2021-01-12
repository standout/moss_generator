# frozen_string_literal: true

require 'moss_generator/stripe_charge_row'
require 'json'

RSpec.describe MossGenerator::StripeChargeRow do
  let(:charge) do
    JSON.parse(File.read('spec/fixtures/stripe_charges.json')).first
  end

  describe '#country_code' do
    subject(:country_code) { described_class.new(charge).country_code }

    context 'when charge has payment method details card country' do
      it { is_expected.to eq('IT') }
    end

    context 'when charge has billing details address country' do
      before do
        charge['payment_method_details'] = nil
        charge['billing_details']['address']['country'] = 'DE'
      end

      it { is_expected.to eq('DE') }
    end

    context 'when charge does not have country' do
      before do
        charge['payment_method_details'] = nil
        charge['billing_details'] = nil
      end

      it 'raises no consumption country error' do
        expect { country_code }.to raise_error(
          MossGenerator::StripeChargeRow::NoConsumptionCountryError
        )
      end
    end
  end

  describe '#amount' do
    subject(:amount) { described_class.new(charge).amount }

    it { is_expected.to eq(248_687) }
  end

  describe '#vat_amount' do
    subject(:vat_amount) { described_class.new(charge).vat_amount }

    it { is_expected.to eq(54_711.14) }
  end
end
