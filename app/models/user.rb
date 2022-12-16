class User < ActiveRecord::Base
  USER_TYPE_REGULAR = 1
  USER_TYPE_ADMIN = 2

  has_many :sessions
  has_many :participants

  validates :nickname, presence: true, uniqueness: true, on: :create
  validates :name, :phone_number, presence: true, on: :create
  validates :email, :uuid, presence: true, uniqueness: true
  validates :user_type, inclusion: { in: [USER_TYPE_REGULAR, USER_TYPE_ADMIN] }

  before_validation :assign_uuid
  before_create :assign_token

  def admin?
    user_type == USER_TYPE_ADMIN
  end

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def assign_token
    self.token ||= SecureRandom.uuid
  end
end
