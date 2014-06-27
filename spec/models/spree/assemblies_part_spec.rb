require 'spec_helper'

module Spree
  describe AssembliesPart do
    let(:variant) { create(:variant) }

    context "get" do
      let(:product) { create(:product) }

      before do
        product.parts.push variant
      end

      it "brings part by product and variant id" do
        subject.class.get(product.id, variant.id).part.should == variant
      end
    end

    describe '.available_count' do
      let(:assembly_part) { assembly.assemblies_parts.first }
      let(:assembly) { create :assembly, parts: { variant => 2 }  }

      before do
        variant.stock_items.first.adjust_count_on_hand 3
      end

      subject { assembly_part.available_count }

      it 'returns the number of times the quantity specified may be fulfilled' do
        expect(subject).to eq 1
      end
    end
  end
end
