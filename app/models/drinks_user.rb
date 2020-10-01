class DrinksUser < ApplicationRecord
  belongs_to :user
  belongs_to :drink

  after_save :recalculate_user_score

  def recalculate_user_score
    score = DrinksUser.where(user_id: user_id).
      after(Date.current.beginning_of_month).
      where.not(abv: nil, volume: nil).
      map{|du| begin du.volume * du.abv / 100.0 rescue 0 end }.sum
    user.update(drink_score: score)
  end

  rails_admin do
    list do
      field :id
      field :user
      field :drink
      field :abv
      field :volume
      include_all_fields
    end
  end
end
