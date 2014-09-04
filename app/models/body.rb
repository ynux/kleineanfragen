class Body < ActiveRecord::Base
  has_many :papers

  validates :name, uniqueness: true
  validates :state, uniqueness: true
end