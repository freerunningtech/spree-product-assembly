module Spree
  Order.class_eval do
    validate :validate_parts_supply

    def validate_parts_supply
      quantity_by_variant = self.line_items.map(&:quantity_by_variant).flatten

      totals = quantity_by_variant.inject({}) do |hash, variant_quantity|
        hash.merge(variant_quantity) do |key, new_count, prev_count|
          new_count + prev_count
        end
      end

      totals.each_pair do |variant, quantity|
        quanitifier = Stock::Quantifier.new(variant)

        unless quanitifier.can_supply? quantity
          errors.add(:line_items, Spree.t(:out_of_stock,
                                          scope: :order_populator,
                                          item: variant.name))
        end
      end
    end
  end
end
