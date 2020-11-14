namespace :daily do
  desc "Person of a day"
  task person_of_a_day: :environment do
    chat_id = Rails.application.credentials.telegram[:bot][:chat_id].to_i
    return unless chat_id.present?
    user = User.where(status: :active).shuffle.sample
    message = Message.find_by(slug: 'person_of_a_day')
    return unless message.present?
    response = message.interpolate({username: "[#{user.full_name_or_username}](tg://user?id=#{user.telegram_id})"})
    response = Message.add_image(response, :drink)
    Telegram.bot.send_message({text: response, chat_id: chat_id, parse_mode: :Markdown})
    if Date.current === Date.current.beginning_of_month
      User.find_each{ |u| u.recalculate_scores }
    end
    User.where.not(untappd_username: [nil, '']).each do |user|
      responses = Drink.sync_untappd(user)
      Telegram.bot.send_message({text: responses.join("\n\n"), chat_id: chat_id, parse_mode: :Markdown})
    end
  end
end

# User.all.map{|user| present = begin ['restricted', 'left'].exclude? Telegram.bot.get_chat_member(chat_id: Rails.application.credentials.telegram[:bot][:chat_id].to_i, user_id: user.telegram_id)['result']['status'] rescue false end; user.update(status: :left) unless present; present;}