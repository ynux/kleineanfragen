class Organization < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  include NkSyncable

  has_and_belongs_to_many :members, class_name: 'Person'

  friendly_id :name, use: :slugged

  has_many :paper_originators, as: :originator, dependent: :destroy
  has_many :papers, -> { answers }, through: :paper_originators

  validates :name, uniqueness: true

  def nomenklatura_dataset
    'ka-parties'
  end
end
