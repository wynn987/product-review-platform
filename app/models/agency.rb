class Agency < ApplicationRecord
  include SwaggerDocs::Agency

  has_many :reviews, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates_presence_of :name, :email, :number
end
