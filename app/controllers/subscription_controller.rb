class SubscriptionController < ApplicationController
  before_action :find_subscription, only: [:unsubscribe]

  def subscribe
    @subscription = Subscription.new(subscription_params)

    # FIXME: validate here
    if @subscription.invalid?
      case @subscription.subtype
      when :body
        # FIXME: redirect back to body
      when :search
        # FIXME: redirect back to search
      else
        # FIXME: render error message
        render status: :bad_request
      end
    end

    if EmailBlacklist.active_and_email(@subscription.email).exists?
      # FIXME: render error message
      render status: :unauthorized
      return
    end

    needs_opt_in = OptIn.unconfirmed_and_email(@subscription.email).empty?
    @subscription.active = !needs_opt_in
    @subscription.save!

    if needs_opt_in
      send_opt_in(@subscription)
    end

    # FIXME: thanks page
  end

  def unsubscribe
    @subscription.active = false
    @subscription.save!

    # FIXME: thanks page
  end

  private

  def send_opt_in(subscription)
    @opt_in = OptIn.create!(email: subscription.email, created_ip: request.remote_ip)
    OptInMailer.opt_in(@opt_in, subscription).deliver_later
  end

  def subscription_params
    params.require(:subscription).permit(:email, :subtype, :query)
  end

  def find_subscription
    @subscription = Subscription.find_by_hash(params[:subscription])
  end
end