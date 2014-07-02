require 'spec_helper'

describe Spree::Product do
  before(:each) do
    @product = FactoryGirl.create(:product, :name => "Foo Bar")
    @master_variant = Spree::Variant.where(is_master: true).find_by_product_id(@product.id)
  end

  describe "Spree::Product.active" do
    before(:each) do
      Spree::Product.delete_all
      @not_available = create(:product, :available_on => Time.now + 15.minutes)
      @future_product = create(:product, :available_on => Time.now + 2.weeks)
    end

    it "includes available, individually saled, non deleted product with a price in the correct currency" do
      product = create(:product, :available_on => Time.now - 15.minutes)
      create(:price, variant: product.master)
      Spree::Product.active('USD').should include(product)
    end

    it "excludes future products" do
      product = create(:product, :available_on => Time.now + 15.minutes)
      Spree::Product.active.should_not include(product)
    end

    it "excludes deleted products" do
      product = create(:product, :deleted_at => Time.now - 15.minutes)
      Spree::Product.active.should_not include(product)
    end

    it "excludes products which are only available as a part" do
      product = create(:product, :individual_sale => false)
      Spree::Product.active.should_not include(product)
    end

    it "excludes products which do not have a price in the correct currency" do
      product = create(:product, :individual_sale => false)
      create(:price, variant: product.master)
      Spree::Product.active('GBP').should_not include(product)
    end
  end

  describe "Spree::Product Assembly" do
    before(:each) do
      @product = create(:product)
      @part1 = create(:product, :can_be_part => true)
      @part2 = create(:product, :can_be_part => true)
      @product.add_part @part1.master, 1
      @product.add_part @part2.master, 4
    end

    it "is an assembly" do
      @product.should be_assembly
    end


    it "cannot be part" do
      @product.should be_assembly
      @product.can_be_part = true
      @product.valid?
      @product.errors[:can_be_part].should == ["assembly can't be part"]
    end

    it 'changing part qty changes count on_hand' do
      @product.set_part_count(@part2.master, 2)
      @product.count_of(@part2.master).should == 2
    end
  end

  describe '#update_assembly_inventory!' do
    let!(:location_a) { create :stock_location }
    let!(:location_b) { create :stock_location }

    let!(:man_nip) { create :variant_with_stock,
                     stock: { location_a => 2,
                              location_b => 5 } }

    context 'when the product is an assembly' do
      let!(:cinco_fone) { create :variant_with_stock,
                          stock: { location_a => 1,
                                   location_b => 2 } }

      let!(:cinco_kit) { create :assembly,
                         parts: { cinco_fone => 1,
                                  man_nip => 2 } }

      subject { cinco_kit.update_assembly_inventory! }

      shared_examples_for 'an assembly' do
        it'sets the inventory level to the minimum part level for each stock location' do
          subject
          expect(location_a.stock_item(cinco_kit.master).count_on_hand).to eq 1
          expect(location_b.stock_item(cinco_kit.master).count_on_hand).to eq 2
        end
      end

      it_behaves_like 'an assembly'

      context "when the assembly doesn't have a stock item at one of the locations" do
        before { cinco_kit.master.stock_items.destroy_all }

        it_behaves_like 'an assembly'

        it 'creates the stock items' do
          expect{ subject }.to change{cinco_kit.stock_items.size}.by(3)
        end
      end
    end

    context 'when the product is not an assembly' do
      it 'does nothing' do
        man_nip.product.update_assembly_inventory!
        expect(location_a.stock_item(man_nip).count_on_hand).to eq 2
        expect(location_b.stock_item(man_nip).count_on_hand).to eq 5
      end
    end
  end
end
