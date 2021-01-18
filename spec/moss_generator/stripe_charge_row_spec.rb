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

  describe '#vat_rate' do
    subject(:vat_rate) { described_class.new(charge).vat_rate }

    before { stub_vat_rates_file }

    context 'when vat rate present for country code' do
      it { is_expected.to eq(22) }
    end

    context 'when no vat rate for country code' do
      before { charge['payment_method_details']['card']['country'] = 'CN' }

      it { is_expected.to be(nil) }
    end
  end

  describe '#amount_without_vat' do
    subject(:amount_without_vat) do
      described_class.new(charge).amount_without_vat
    end

    before { stub_vat_rates_file }

    context 'when currency is sek' do
      it { is_expected.to eq(2038.42) }
    end

    context 'when currency is not in sek' do
      before { charge['balance_transaction']['currency'] = 'usd' }

      it 'raises not in sek error' do
        expect { amount_without_vat }.to raise_error(
          MossGenerator::StripeChargeRow::NotInSwedishKronorError
        )
      end
    end
  end

  describe '#skippable' do
    subject(:company) { described_class.new(charge).skippable? }

    context 'when no vat number, status is succeded and refunded false' do
      before { charge['metadata'] = nil }

      it { is_expected.to be(false) }
    end

    context 'when vat number is present' do
      before { charge['metadata']['vat_number'] = vat_number }

      context 'when the vat number is valid' do
        let(:vat_number) { 'DE345789003' }

        it { is_expected.to be(true) }
      end

      context 'when the vat number is not valid' do
        let(:vat_number) { 'DE345/89003' }

        it { is_expected.to be(false) }
      end
    end

    context 'when status is not succeeded' do
      before { charge['status'] = 'processing' }

      it { is_expected.to be(true) }
    end

    context 'when refunded is true' do
      before { charge['refunded'] = true }

      it { is_expected.to be(true) }
    end
  end

  describe '#vat_amount' do
    subject(:vat_amount) { described_class.new(charge).vat_amount }

    before { stub_vat_rates_file }

    it { is_expected.to eq(44_8.45) }
  end
end
