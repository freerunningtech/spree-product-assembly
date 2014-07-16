require 'spec_helper'

describe Spree::Order do
  describe '.validate_part_supply' do
    let(:order) { create :order }
    let(:cinco_food_tube) { create :base_product, name: 'cinco food tube' }
    let(:cinco_pack) { create :assembly, name: 'cinco pack', parts: { cinco_food_tube.master => 1 } }

    subject { order.valid? }

    context 'an order with no line_items' do
      it { expect(order).to be_valid }
    end

    before do
      allow_any_instance_of(Spree::StockItem).to receive(:backorderable).
        and_return false

      cinco_food_tube.stock_items.first.adjust_count_on_hand 2
    end

    shared_examples_for "a fulfillable order" do
      it 'does not add an error' do
        subject
        expect(order.errors).to be_empty
      end
    end

    context 'when the items are capable of backorder' do
      before do
        allow_any_instance_of(Spree::StockItem).to receive(:backorderable).
          and_return true

        create :line_item, variant: cinco_pack.master, quantity: 2,
          order: order

        create :line_item, variant: cinco_food_tube.master, quantity: 1,
          order: order
      end

      it_behaves_like 'a fulfillable order'
    end

    context "when there isn't enough stock to fulfill both a line item and an assembly" do
      before do
        create :line_item, variant: cinco_pack.master, quantity: 2,
          order: order

        create :line_item, variant: cinco_food_tube.master, quantity: 1,
          order: order

        order.reload
      end

      it 'adds an error to the order' do
        # cinco pack has 1 x food tubes
        # order has 2 x cinco pack, 1 x food tube, for a total of 3 x food tube's
        # 2 food tube's in stock
        subject
        expect(order.errors.size).to eq 1
        expect(order.errors.full_messages.first).to match(/cinco food tube is out of stock/)
      end
    end

    context 'when the order can be filled' do
      before do
        create :line_item, variant: cinco_pack.master, quantity: 1,
          order: order

        create :line_item, variant: cinco_food_tube.master, quantity: 1,
          order: order
      end

      it_behaves_like 'a fulfillable order'
    end
  end
end
