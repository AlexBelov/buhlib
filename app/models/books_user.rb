class BooksUser < ApplicationRecord
  belongs_to :user
  belongs_to :book

  after_save :recalculate_user_score

  def recalculate_user_score
    score = BooksUser.after(Date.current.beginning_of_month).
      where(user_id: user_id, finished: true).count
    user.update(book_score: score)
  end
end