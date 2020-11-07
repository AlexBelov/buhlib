class Message < ApplicationRecord
  def interpolate(params)
    content % params
  end

  def self.add_random_image(text)
    "[\u200c](#{Image.random})#{text}"
  end

  def self.add_image(text, image_type)
    "[\u200c](#{Image.random(image_type)})#{text}"
  end

  def self.handle_achievements_and_ranks(user)
    notification_response = ''
    has_book_achievement = false
    achievements = user.check_for_achievements
    if achievements.present?
      notification_response += achievements.map{|a| a.response(user)}.join("\n")
      has_book_achievement ||= achievements.any?{|a| a.entity == 'book'}
    end
    ranks = user.check_for_ranks
    if ranks.present?
      notification_response += "\n" if achievements.present?
      notification_response += ranks.map{|a| a.response(user)}.join("\n")
      has_book_achievement ||= ranks.any?{|a| a.entity == 'book'}
    end
    return nil unless notification_response.present?
    add_image(notification_response, has_book_achievement ? :book : :drink)
  end
end
