class User < ActiveRecord::Base
  has_many :sessions
  has_many :participants

  validates :email, :uuid, presence: true, uniqueness: true

  before_validation :assign_uuid
  before_create :assign_token

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def assign_token
    self.token ||= SecureRandom.uuid
  end
end
