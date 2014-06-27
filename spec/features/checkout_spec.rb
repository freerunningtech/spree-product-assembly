require 'spec_helper'

describe "Checkout" do
  let!(:country) { create(:country, :name => "United States", :states_required => true) }
  let!(:state) { create(:state, :name => "Ohio", :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let(:product) { create(:product, :name => "RoR Mug") }
  let(:variant) { create(:variant) }

  stub_authorization!

  before { product.parts.push variant }

  shared_context "purchases product with part included" do
    before do
      add_product_to_cart product
      click_button "Checkout"

      fill_in "order_email", :with => "ryan@spreecommerce.com"
      fill_in_address

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("delivery"))
      page.should have_content(variant.product.name)

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("payment"))

      click_button "Save and Continue"
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      page.should have_content(variant.product.name)
    end
  end

  context "backend order shipments UI", js: true do

    context "ordering only the product assembly" do
      include_context "purchases product with part included"

      it "views parts bundled as well" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end

    context "ordering assembly and the part as individual sale" do
      before do
        add_product_to_cart variant.product
      end

      include_context "purchases product with part included"

      it "views parts bundled and not" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end

  end

  context 'purchasing an assembly' do
    context 'and the part as individual sale' do
      context 'and the products are not backorderable' do
        before { Spree::StockItem.update_all backorderable: false }

        context 'and there is enough stock to fufill the order' do
          before do
            variant.stock_items.first.set_count_on_hand 2
            product.stock_items.first.set_count_on_hand 1
          end

          it 'can proceed through checkout' do
            add_product_to_cart variant.product
            add_product_to_cart product
            click_button "Checkout"
            expect(current_path).to eql(spree.checkout_state_path("address"))
          end
        end

        context "and the part doesn't have enough stock to fill the order" do
          before do
            variant.stock_items.first.set_count_on_hand 1
            product.stock_items.first.set_count_on_hand 1
          end

          it 'cannot proceed to checkout' do
            add_product_to_cart variant.product
            add_product_to_cart product
            click_button "Checkout"

            expect(current_path).to eql(spree.cart_path)
            expect(page).to have_content "#{variant.name} is out of stock"
          end
        end
      end
    end
  end


  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", :with => "Ryan"
    fill_in "#{address}_lastname", :with => "Bigg"
    fill_in "#{address}_address1", :with => "143 Swan Street"
    fill_in "#{address}_city", :with => "Richmond"
    select "Ohio", :from => "#{address}_state_id"
    fill_in "#{address}_zipcode", :with => "12345"
    fill_in "#{address}_phone", :with => "(555) 555-5555"
  end

  def add_product_to_cart product
    visit spree.root_path
    click_link product.name
    click_button "add-to-cart-button"
  end
end
