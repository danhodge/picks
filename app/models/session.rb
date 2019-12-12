class Session < ActiveRecord::Base
  belongs_to :user

  validates :token, :expires_at, presence: true

  before_validation :assign_token

  def expired?
    Time.now > expires_at
  end

  private

  def assign_token
    return if token

    self.token = SecureRandom.uuid
    self.expires_at = Time.now + 1.month
  end
end
