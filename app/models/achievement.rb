class Achievement < ApplicationRecord
  enum entity: [:drink, :book]

  has_and_belongs_to_many :users

  def self.check_for_achievements(user)
    strong_alcohol_threshold = Config.find_by(key: 'strong_alcohol_threshold').value.to_f
    drinks_today_relation = user.drinks_users.today
    drinks_today = drinks_today_relation.count
    books_today = user.books_users.today.count
    books_finished_today = user.books_users.today.where(finished: true).count
    drinks_this_week = user.drinks_users.after(Time.current.beginning_of_week).count
    books_this_week = user.books_users.after(Time.current.beginning_of_week).count
    books_this_month = user.books_users.after(Time.current.beginning_of_week).count
    books_finished_this_month = user.books_users.where(finished: true).after(Time.current.beginning_of_week).count
    drinks_this_month = user.drinks_users.after(Time.current.beginning_of_week).count
    abv_sequence = drinks_today_relation.pluck(:abv).compact.map{|abv| abv >= strong_alcohol_threshold ? 'strong' : 'weak'}.join(',')
    abv_relations = drinks_today_relation.each_with_index.map do |d, i|
      if i == 0
        '0'
      elsif d.abv == drinks_today_relation[i-1].abv
        '0'
      else
        d.abv > drinks_today_relation[i-1].abv ? '+1' : '-1'
      end
    end.join(',')
    volume_today = drinks_today_relation.pluck(:volume).compact.sum
    volume_relations = drinks_today_relation.each_with_index.map do |d, i|
      if i == 0
        '0'
      elsif d.volume == drinks_today_relation[i-1].volume
        '0'
      else
        d.volume > drinks_today_relation[i-1].volume ? '+1' : '-1'
      end
    end.join(',')
    kinds_of_alcohol_today = Drink.where(id: drinks_today_relation.pluck(:drink_id)).pluck(:name).uniq.compact.count
    achievements = Achievement.all.
      filter{|a| begin eval(a.condition) rescue false end}.
      filter{|a| !user.has_achievement_today?(a)}
    return nil unless achievements.present?
    user.achievements << achievements
    achievements
  end

  def response(user)
    message = Message.find_by(slug: 'achievement')
    return unless message.present?
    response = message.interpolate({full_name: user.full_name, name: name, description: description})
  end

  rails_admin do
    list do
      field :id
      field :entity
      field :name
      field :condition
      include_all_fields
    end
  end
end
