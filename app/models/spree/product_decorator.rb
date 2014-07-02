Spree::Product.class_eval do
  has_and_belongs_to_many  :parts, :class_name => "Spree::Variant",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "assembly_id", :association_foreign_key => "part_id"

  has_many :assemblies_parts, :class_name => "Spree::AssembliesPart",
    :foreign_key => "assembly_id"

  scope :individual_saled, -> { where(["spree_products.individual_sale = ?", true]) }

  scope :search_can_be_part, ->(query){ not_deleted.available.joins(:master)
    .where(arel_table["name"].matches("%#{query}%").or(Spree::Variant.arel_table["sku"].matches("%#{query}%")))
    .where(can_be_part: true)
    .limit(30)
  }

  scope :active, lambda { |*args|
    not_deleted.individual_saled.available(nil, args.first)
  }

  validate :assembly_cannot_be_part, :if => :assembly?

  def add_part(variant, count = 1)
    set_part_count(variant, count_of(variant) + count)
  end

  def remove_part(variant)
    set_part_count(variant, 0)
  end

  def set_part_count(variant, count)
    ap = assemblies_part(variant)
    if count > 0
      ap.count = count
      ap.save
    else
      ap.destroy
    end
    reload
  end

  def assembly?
    parts.present?
  end

  def count_of(variant)
    ap = assemblies_part(variant)
    # This checks persisted because the default count is 1
    ap.persisted? ? ap.count : 0
  end

  def assembly_cannot_be_part
    errors.add(:can_be_part, Spree.t(:assembly_cannot_be_part)) if can_be_part
  end

  def update_assembly_inventory!
    assemblies_parts.inject({}) do |assembly_count, part|
      assembly_count.merge(part.count_by_stock_location) do |_, current_min, quantity |
        [ current_min, quantity ].min
      end
    end.each_pair do |location, quantity|
      location.stock_item(self.master).set_count_on_hand quantity
    end
  end

  private
  def assemblies_part(variant)
    Spree::AssembliesPart.get(self.id, variant.id)
  end
end
