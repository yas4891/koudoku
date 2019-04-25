StripeEvent.configure do |events|
  events.subscribe 'charge.failed' do |event|
    # aborts execution for events that came through Stripe Connect webhooks
    # they are irrelevant to Koudoku
    unless event.try(:account)
      stripe_id = event.data.object['customer']
      subscription = ::Subscription.find_by_stripe_id(stripe_id)
      subscription.charge_failed
    end
  end
  
  events.subscribe 'invoice.payment_succeeded' do |event|
    unless event.try(:account)
      stripe_id = event.data.object['customer']
      amount = event.data.object['total'].to_f / 100.0
      subscription = ::Subscription.find_by_stripe_id(stripe_id)
      subscription.payment_succeeded(amount)
    end
  end
  
  events.subscribe 'charge.dispute.created' do |event|
    unless event.try(:account)
      stripe_id = event.data.object['customer']
      subscription = ::Subscription.find_by_stripe_id(stripe_id)
      subscription.charge_disputed
    end
  end
  
  events.subscribe 'customer.subscription.deleted' do |event|
    unless event.try(:account)
      stripe_id = event.data.object['customer']
      subscription = ::Subscription.find_by_stripe_id(stripe_id)
      subscription.subscription_owner.try(:cancel)
    end
  end
end