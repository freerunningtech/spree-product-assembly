FactoryGirl.define do
  factory :assembly, class: 'Spree::Product', parent: :base_product do
    ignore do
      parts {}
    end

    trait :with_parts do |n|
      ignore do
        number_of_parts 1
      end

      after :create do |assembly, evaluator|
        evaluator.number_of_parts.times do
          assembly.add_part create :variant
        end
      end
    end

    after :create do |assembly, evaluator|
      evaluator.parts.each_pair do |part, quantity|
        assembly.add_part part, quantity
      end
      assembly.save!
    end
  end
end
