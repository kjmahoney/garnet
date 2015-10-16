class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true, format: {with: /\A[a-zA-Z0-9\-_]+\z/, message: "Only letters, numbers, hyphens, and underscores are allowed."}
  validates :github_id, allow_blank: true, uniqueness: true
  validate :validates_name_if_no_github_id

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  has_many :observations
  has_many :admin_observations, class_name: "Observation", foreign_key: "admin_id"

  has_many :submissions
  has_many :admin_submissions, class_name: "Submission", foreign_key: "admin_id"
  has_many :assignments, through: :submissions

  has_many :attendances
  has_many :admin_attendances, class_name: "Attendance", foreign_key: "admin_id"
  has_many :events, through: :attendances

  before_save :before_save
  attr_accessor :password

  def validates_name_if_no_github_id
    if !self.github_id && self.name.strip.blank?
      errors[:base].push("Please include your full name!")
    end
  end

  def before_save
    self.username.downcase!
    if self.password && !self.password.strip.blank?
      self.password_digest = User.new_password(self.password)
    end
  end

  def to_param
    "#{self.username}"
  end

  def self.named username
    User.find_by(username: username)
  end

  def name
    read_attribute(:name) || username
  end

  def first_name
    return "" unless name.present?
    name.split.first.capitalize
  end

  def last_name
    return "" unless name.present?
    name.split.last.capitalize
  end

  def self.new_password password
    BCrypt::Password.create(password)
  end

  def password_ok? password
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def was_observed group_path, admin_username, body, status
    self.observations.create!({
      group_id: Group.at_path(group_path).id,
      admin_id: User.named(admin_username).id,
      body: body,
      status: status
    })
  end

end
