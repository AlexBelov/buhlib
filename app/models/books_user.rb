class BooksUser < ApplicationRecord
  belongs_to :user
  belongs_to :book

  after_save :recalculate_user_score
  before_destroy :stop_destroy

  def recalculate_user_score
    score = BooksUser.after(Date.current.beginning_of_month).
      where(user_id: user_id, finished: true).count
    user.update(book_score: score)
  end

  def stop_destroy
    errors.add(:base, :undestroyable)
    throw :abort
  end
end