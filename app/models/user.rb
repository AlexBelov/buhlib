class User < ApplicationRecord
  has_one :admin
  has_many :drinks_users
  has_many :books_users
  has_many :achievements_users
  has_and_belongs_to_many :books
  has_and_belongs_to_many :drinks
  has_and_belongs_to_many :achievements
  has_and_belongs_to_many :ranks

  def full_name
    [first_name, last_name].join(' ').strip
  end

  def full_name_or_username
    full_name.present? ? full_name : username
  end

  def title
    "##{id} #{username}"
  end

  def check_for_achievements
    Achievement.check_for_achievements(self)
  end

  def check_for_ranks
    Rank.check_for_ranks(self)
  end

  def has_achievement?(achievement)
    achievements_users.where(achievement_id: achievement.id).present?
  end

  def has_achievement_today?(achievement)
    achievements_users.today.where(achievement_id: achievement.id).present?
  end

  def self.get_full_name(from)
    return 'Анон' unless from.present?
    [from['first_name'], from['last_name']].join(' ').strip
  end

  def self.handle_user(from)
    return true unless from.present?
    user = User.where(telegram_id: from['id']).first_or_create(first_name: from['first_name'], last_name: from['last_name'], username: from['username'])
    if user.first_name != from['first_name'] || user.last_name != from['last_name'] || user.username != from['username']
      user.update(first_name: from['first_name'], last_name: from['last_name'], username: from['username'])
    end
    user
  end

  def books_this_month
    books_users.after(Time.current.beginning_of_month).count
  end

  def books_finished_this_month
    books_users.where(finished: true).after(Time.current.beginning_of_month).count
  end

  def drinks_today
    drinks_users.today.count
  end

  def drinks_this_month
    drinks_users.after(Time.current.beginning_of_month).count
  end

  def recalculate_scores
    drink_score = DrinksUser.where(user_id: id).
      after(Date.current.beginning_of_month).
      where.not(abv: nil, volume: nil).
      map{|du| begin du.volume * du.abv / 100.0 rescue 0 end }.sum
    book_score = BooksUser.where(user_id: id, finished: true).
      after(Date.current.beginning_of_month).count
    update(drink_score: drink_score, book_score: book_score)
  end
end
