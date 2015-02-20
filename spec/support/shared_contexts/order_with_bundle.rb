shared_context "product is ordered as individual and within a bundle" do
  let(:line_items) { build_stubbed_list(:line_item, 5) }
  let(:order) { build_stubbed(:order) }
  let(:parts) { build_stubbed_list(:variant, 3) }

  let(:bundle_variant) { order.line_items.first.variant }
  let(:bundle) { bundle_variant.product }

  let(:common_product) { order.line_items.last.variant }

  before do
    allow(order).to receive(:line_items).and_return(line_items)
    expect(bundle_variant).to_not be_nil
    expect(bundle_variant).to_not eql common_product

    allow(bundle).to receive(:parts).and_return(parts + Array(common_product))
  end
end
