Spree::OrderContents.class_eval do

  durably_decorate :update_cart, mode: 'strict', sha: 'f3e37d0ffd8c089d1b246e268679d5430886f2c2' do |params|
    order.assign_attributes( params )
    original_update_cart( params ) if order.valid? :checkout
  end

end
