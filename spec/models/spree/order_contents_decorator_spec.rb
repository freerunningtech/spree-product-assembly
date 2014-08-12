require 'spec_helper'

describe Spree::OrderContents do
  describe '.update_cart' do
    let(:order) { build :order }
    let(:params) { {} }

    it 'validates the parts supply' do
      expect(order).to receive(:validate_parts_supply)
      order.contents.update_cart params
    end
  end
end
