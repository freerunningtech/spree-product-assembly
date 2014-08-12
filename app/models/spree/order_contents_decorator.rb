Spree::OrderContents.class_eval do
  alias_method :old_update_cart, :update_cart

  def update_cart(params)
    order.assign_attributes( params )
    old_update_cart( params ) if order.valid? :checkout
  end
end
