# frozen_string_literal: true

require 'moss_generator/stripe_charge_row'
require 'json'
require 'date'

RSpec.describe MossGenerator::StripeChargeRow do
  let(:charge) do
    JSON.parse(File.read('spec/fixtures/stripe_charges.json')).first
  end

  let(:exchange_rates) { read_exchange_rates }
  let(:stripe_charge_row) { described_class.new(charge, exchange_rates) }

  describe '#country_code' do
    subject(:country_code) { stripe_charge_row.country_code }

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
    subject(:vat_rate) { stripe_charge_row.vat_rate }

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
    subject(:amount_without_vat) { stripe_charge_row.amount_without_vat }

    before { stub_vat_rates_file }

    context 'when currency is eur' do
      it { is_expected.to eq(205.9) }
    end

    context 'when currency is not in eur' do
      context 'when currency exist in exchange rates list' do
        before do
          charge['currency'] = 'usd'
          # Ensure we have a timestamp within the exchange rates list
          charge['created'] = Date.parse('2021-01-01').to_time.to_i
        end

        it { is_expected.to eq(169.11) }

        it 'calls on method to exchanges the amount to eur' do
          allow(stripe_charge_row)
            .to receive(:calculate_amount_from_rate).and_call_original

          amount_without_vat

          expect(stripe_charge_row)
            .to have_received(:calculate_amount_from_rate)
        end
      end

      context 'when currency does not exist in exchange rates list' do
        before do
          charge['currency'] = 'bog'
          # Ensure we have a timestamp within the exchange rates list
          charge['created'] = Date.parse('2021-01-01').to_time.to_i
        end

        it 'raises error' do
          expect { amount_without_vat }.to raise_error(
            MossGenerator::StripeChargeRow::NoExchangeRateForCurrencyOrDateError
          )
        end
      end
    end
  end

  describe '#skippable' do
    subject(:company) { stripe_charge_row.skippable? }

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

    context 'when the charge is made inside EU' do
      before { charge['payment_method_details']['card']['country'] = 'FI' }

      it { is_expected.to be(false) }
    end

    context 'when the charge is made outside of EU' do
      before { charge['payment_method_details']['card']['country'] = 'US' }

      it { is_expected.to be(true) }
    end

    context 'when the charge is made in Sweden ' do
      before { charge['payment_method_details']['card']['country'] = 'SE' }

      it { is_expected.to be(true) }
    end

    context 'when the charge is has no country' do
      before { charge['payment_method_details']['card']['country'] = nil }

      it { is_expected.to be(true) }
    end

    context 'when refunded is true' do
      before { charge['refunded'] = true }

      it { is_expected.to be(true) }
    end
  end

  describe '#vat_amount' do
    subject(:vat_amount) { stripe_charge_row.vat_amount }

    before { stub_vat_rates_file }

    it { is_expected.to eq(45.3) }
  end
end
