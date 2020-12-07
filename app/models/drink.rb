class Drink < ApplicationRecord
  has_and_belongs_to_many :users

  def self.handle_drink(user, payload)
    file_id = payload['photo'].first['file_id']
    return unless payload['caption'].include?('#')
    tags = payload['caption'].split('#').map(&:strip).filter{|t| t.present?}.map(&:downcase)
    return nil unless tags.present?
    drink = Drink.where(name: tags).first
    return "Не могу найти напиток в картотеке" unless drink.present?
    abv = handle_abv(tags)
    volume = handle_volume(tags)
    incorrect_abv = !abv.present? || abv.present? && (abv <= 0 || abv > 100)
    incorrect_volume = !volume.present? || volume.present? && (volume <= 0 || volume >= 10000)
    if incorrect_abv || incorrect_volume
      return "Проверьте правильность заполнения тегов: #{drink.name.gsub(/_/, ' ')} #{abv || '0'}% #{volume.to_i || '0'} мл."
    end
    DrinksUser.create(user: user, drink: drink, abv: abv, volume: volume, file_id: file_id)
    response = "Добавлено #{drink.name.gsub(/_/, ' ')} #{abv || '0'}% #{volume.to_i || '0'} мл\nТеперь #{user.full_name} выпил #{Drink.pluralize(user.drinks.count)}! (#{Drink.pluralize(user.drinks_today)} за сегодня)"
    # if abv > 30 && volume.to_i >= 100
    #   response += "\n\n@trititaty одобряет!"
    # elsif abv < 10 && volume.to_i >= 1000
    #   response += "\n\n@BagOfMilk одобряет!"
    # end
    return response
  rescue Exception => e
    puts "Exception in handle drink - #{e.message}".red
    nil
  end

  def self.pluralize(count)
    "#{count} #{Russian::p(count, 'раз', 'раза', 'раз')}"
  end

  def self.handle_abv(tags)
    abv_tag = tags.find{|t| t.match(/^(abv\d+|a\d+|а\d+)/)}
    abv_tag.scan(/[\d|_]+/).first.gsub('_', '.').to_f
  rescue
    nil
  end

  def self.handle_volume(tags)
    volume_tag = tags.find{|t| t.match(/^(vol\d+|v\d+)/)}
    volume_tag.gsub('vol', '').scan(/\d+/).first.to_f
  rescue
    nil
  end

  def self.sync_untappd(user)
    return unless user.untappd_username.present?
    drink = Drink.where(name: 'пиво').first
    feed = Untappd::User.feed(user.untappd_username)
    responses = feed['checkins']['items'].map do |checkin|
      begin
        checkin_at = Time.parse(checkin['created_at'])
        next unless checkin_at > user.untappd_synced_at
        comment = checkin['checkin_comment']
        comment_tag = comment.present? ? "#{comment}\n\n" : ''
        photo = begin checkin['media']['items'][0]['photo']['photo_img_md'] rescue nil end
        photo_tag = photo.present? ? "[\u200c](#{photo})" : ''
        volume = comment.scan(/(\d+)\s?[мл|ml]/).flatten.first.to_f
        volume = 500 unless volume > 0
        abv = checkin['beer']['beer_abv'].to_f
        beer_name = checkin['beer']['beer_name']
        beer_style = checkin['beer']['beer_style']
        next if abv <= 0 || volume <= 0
        DrinksUser.create(user: user, drink: drink, abv: abv, volume: volume, untappd: true)
        "*Untappd*: добавлено пиво (#{beer_name} | #{beer_style}) #{abv || '0'}% #{volume.to_i || '0'} мл\n\n#{comment_tag}Теперь #{user.full_name} выпил #{Drink.pluralize(user.drinks.count)}! (#{Drink.pluralize(user.drinks_today)} за сегодня)#{photo_tag}"
      rescue
        next
      end
    end
    user.update(untappd_synced_at: Time.current)
    responses.compact
  end
end
