namespace :daily do
  desc "Person of a day"
  task person_of_a_day: :environment do
    chat_id = Rails.application.credentials.telegram[:bot][:chat_id].to_i
    return unless chat_id.present?
    user = User.where.not(username: [nil, '']).sample
    message = Message.find_by(slug: 'person_of_a_day')
    return unless message.present?
    response = message.interpolate({username: "@#{user.username}"})
    response = Message.add_image(response, :drink)
    Telegram.bot.send_message({text: response, chat_id: chat_id, parse_mode: :Markdown})
    if Date.current === Date.current.beginning_of_month
      User.find_each{ |u| u.recalculate_scores }
    end
  end
end