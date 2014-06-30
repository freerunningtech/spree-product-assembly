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

    describe '#count_by_stock_location!' do
      let!(:location_a) { create :stock_location }
      let!(:cinco_fone) { create :variant_with_stock,
                          stock: { location_a => 9 } }
      let!(:cinco_kit) { create :assembly, parts: { cinco_fone => 2} }
      let(:part) { cinco_kit.assemblies_parts.first }

      subject { part.count_by_stock_location }

      it 'is lists how many assemblies can be supplied with this part per stock location' do
        expect(subject).to eq(location_a => 4)
      end
    end
  end
end
