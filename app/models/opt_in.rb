class OptIn < ApplicationRecord
  validates :email, presence: true
  before_create :assign_confirmation_token

  def to_param
    confirmation_token
  end

  def confirmed?
    !confirmed_at.nil?
  end

  def self.unconfirmed_and_email(val)
    where('confirmed_at IS NOT NULL').where(email: val)
  end

  def assign_confirmation_token
    self.confirmation_token = Digest::SHA1.hexdigest([email, Time.now.to_i].join)
  end
end