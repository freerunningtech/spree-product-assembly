FactoryGirl.define do
  factory :variant_with_stock, parent: :variant do
    ignore do
      stock {}
    end

    after :create do |variant, evaluator|
      evaluator.stock.each_pair do |stock_location, new_count_on_hand|
        stock_location.stock_item(variant).set_count_on_hand new_count_on_hand
      end
    end
  end
end
