class Person < ActiveRecord::Base
  has_and_belongs_to_many :organizations

  has_many :paper_originators, as: :originator
  has_many :papers, through: :paper_originators
end