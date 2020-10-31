class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include ActionView::Helpers::DateHelper

  def message(message)
    response = '';
    user = User.handle_user(message['from'])
    user.update_columns(last_message_at: Time.current)
    check_for_achievements = false
    if message['new_chat_participant'].present?
      msg = Message.find_by(slug: 'welcome')
      return unless msg.present?
      response = msg.interpolate({first_name: User.get_full_name(message['new_chat_participant'])})
      response = Message.add_image(response, :drink)
    elsif message['text'].present? && message['text'] == '!kick'
      response = kick_or_ban(message, false)
    elsif message['text'].present? && message['text'] == '!ban'
      response = kick_or_ban(message, true)
    elsif message['text'].present? && message['text'].include?('!mute')
      response = mute_or_unmute(message, false)
    elsif message['text'].present? && message['text'].include?('!unmute')
      response = mute_or_unmute(message, true)
    elsif message['text'].present?
      response = Book.detect_book_mention(message['text'])
    elsif message['photo'].present?
      response = Drink.handle_drink(user, message)
      check_for_achievements = response.present?
    end
    return unless response.present?
    respond_with :message, text: response, parse_mode: :Markdown
    return unless check_for_achievements
    ar_response = Message.handle_achievements_and_ranks(user)
    respond_with :message, text: ar_response, parse_mode: :Markdown if ar_response.present?
  rescue Exception => e
    puts "Error in message handler - #{e.message}".red
    return true
  end

  def rules!(data = nil, *)
    message = Message.find_by(slug: 'rules')
    return unless message.present?
    response = message.interpolate({})
    return unless response.present?
    respond_with :message, text: response
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def help!(data = nil, *)
    message = Message.find_by(slug: 'help')
    return unless message.present?
    response = message.interpolate({bot_commands: BotCommand.list_of_commands})
    return unless response.present?
    respond_with :message, text: response
  end

  def roll!(data = nil, *)
    result = ['Пить =)', 'Не пить =('].sample
    result = 'В пятницу только пить!' if Date.current.wday == 5
    response = "Пить или не пить? - *#{result}*"
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def reading!(data = nil, *)
    response = BooksUser.where(finished: false).
      includes(:user, :book).order(created_at: :desc).
      each_with_index.map{|bu, i| "#{i+1}. #{bu.user.full_name} читает #{bu.book.url}" }.
      join("\n")
    respond_with :message, text: "Книги, читаемые сейчас\n" + response, disable_web_page_preview: true
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def top_drinks!(data = nil, *)
    ordered_drinks = Drink.joins(:users).order("COUNT(users.id) DESC").group("drinks.id").limit(5)
    response = ordered_drinks.each_with_index.map{|d, i| "#{i + 1}. #{d.name}"}.join("\n")
    respond_with :message, text: "*Топ бухла*\n" + response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def top_readers!(data = nil, *)
    ordered_users = User.where('book_score > 0').order(book_score: :desc).limit(10)
    response = ordered_users.each_with_index.map{|u, i| "#{i + 1}. #{u.full_name} - #{u.book_score.to_i}"}.join("\n")
    respond_with :message, text: "*Топ читателей*\n" + response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def top_drinkers!(data = nil, *)
    ordered_users = User.where('drink_score > 0').order(drink_score: :desc).limit(10)
    response = ordered_users.each_with_index.map{|u, i| "#{i + 1}. #{u.full_name} - #{u.drink_score.to_i} мл"}.join("\n")
    respond_with :message, text: "*Топ алкоголиков (в пересчете на 100% спирт)*\n" + response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def has_drink!(data = nil, *)
    existing_drink = Drink.find_by(name: data.downcase)
    response = if existing_drink.present?
      "У нас есть напиток *#{existing_drink.name}*"
    else
      "Напиток *#{data.downcase}* ещё не добавлен. Добавление возможно с помощью команды */add_drink *"
    end
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def add_drink!(data = nil, *)
    return unless data.present?
    existing_drink = Drink.find_by(name: data.downcase)
    response = if existing_drink.present?
      "У нас уже есть напиток *#{existing_drink.name}*"
    else
      new_drink = Drink.where(name: data.downcase).first_or_create
      "Напиток *#{new_drink.name}* добавлен. Теперь его можно использовать в качестве тега"
    end
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def add_book!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    response = Book.add_book(user, data)
    return unless response.present?
    respond_with :message, text: response, parse_mode: :Markdown
    ar_response = Message.handle_achievements_and_ranks(user)
    respond_with :message, text: ar_response, parse_mode: :Markdown if ar_response.present?
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def finish_book!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    response = Book.finish_book(user, data)
    return unless response.present?
    respond_with :message, text: response, parse_mode: :Markdown
    ar_response = Message.handle_achievements_and_ranks(user)
    respond_with :message, text: ar_response, parse_mode: :Markdown if ar_response.present?
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def all_achievements!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    response = Achievement.all.each_with_index.map{|a, i| "#{i+1}. *#{a.name}* - _#{a.description}_"}.join("\n")
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def my_achievements!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    response = user.achievements.uniq.each_with_index.map{|a, i| "#{i+1}. *#{a.name}* - _#{a.description}_"}.join("\n")
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def find_drink_buddy!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    buddy = User.where.not(id: user.id, username: [nil, '']).sample
    message = Message.find_by(slug: 'drink_buddy')
    return unless message.present?
    response = message.interpolate({master_name: "@#{user.username}", buddy_name: "@#{buddy.username}"})
    response = Message.add_image(response, :drink)
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def score!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    drink_score = DrinksUser.where(user_id: user.id).
      where.not(abv: nil, volume: nil).
      map{|du| begin du.volume * du.abv / 100.0 rescue 0 end }.sum
    book_score = BooksUser.where(user_id: user.id, finished: true).count
    respond_with :message, text: "*100% Спирт*: #{user.drink_score.to_i} мл (всего #{drink_score.to_i} мл)\n*Законченные книги*: #{user.book_score.to_i} (всего #{book_score.to_i})", parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  private

  def kick_or_ban(message, ban = false)
    user = User.handle_user(message['from'])
    return unless user.present? && user.admin.present?
    return unless message['reply_to_message'].present?
    new_participant = message['reply_to_message']['new_chat_participant']
    message_from = message['reply_to_message']['from']
    cannot_kick_usernames = Admin.where.not(user_id: nil).includes(:user).pluck(:username).concat([Rails.application.credentials.telegram[:bot][:username]])
    user_id, name = if new_participant.present?
      [new_participant['id'], [new_participant['first_name'], new_participant['last_name']].join(' ')]
    elsif message_from.present? && !cannot_kick_usernames.include?(message_from['username'])
      [message_from['id'], [message_from['first_name'], message_from['last_name']].join(' ')]
    end
    return "Не могу #{ban ? 'забанить' : 'кикнуть'} пользователя" unless user_id.present?
    until_date = ban ? (Time.current + 2.years).to_i : (Time.current + 1.minute).to_i
    Telegram.bot.kick_chat_member({chat_id: Rails.application.credentials.telegram[:bot][:chat_id].to_i, user_id: user_id, until_date: until_date})
    "*#{user.full_name}* #{ban ? 'забанил' : 'кикнул'} *#{name}*"
  end

  def mute_or_unmute(message, unmute = false)
    user = User.handle_user(message['from'])
    mute_for = message['text'].gsub('!mute', '').strip
    mute_for = '1 hour' unless mute_for.present?
    mute_for = '3 years' if unmute
    return unless user.present? && user.admin.present?
    return unless message['reply_to_message'].present?
    new_participant = message['reply_to_message']['new_chat_participant']
    message_from = message['reply_to_message']['from']
    cannot_kick_usernames = Admin.where.not(user_id: nil).includes(:user).pluck(:username).concat([Rails.application.credentials.telegram[:bot][:username]])
    user_id, name = if new_participant.present?
      [new_participant['id'], [new_participant['first_name'], new_participant['last_name']].join(' ')]
    elsif message_from.present? && !cannot_kick_usernames.include?(message_from['username'])
      [message_from['id'], [message_from['first_name'], message_from['last_name']].join(' ')]
    end
    return "Не могу замьютить пользователя" unless user_id.present?
    value = begin mute_for.scan(/\d+/)[0].to_i rescue 1 end
    mute_time, unit =
    if mute_for.include?('year')
      value.years
    elsif mute_for.include?('month')
      value.months
    elsif mute_for.include?('week')
      value.weeks
    elsif mute_for.include?('day')
      value.days
    elsif mute_for.include?('hour')
      value.hours
    else
      value.minutes
    end
    until_time = Time.current + mute_time
    Telegram.bot.restrict_chat_member({
      chat_id: Rails.application.credentials.telegram[:bot][:chat_id].to_i,
      user_id: user_id,
      permissions: {
        can_send_messages: unmute,
        can_send_media_messages: unmute,
        can_send_polls: unmute,
        can_send_other_messages: unmute,
        can_add_web_page_previews: unmute
      },
      until_date: until_time.to_i
    })
    return "*#{user.full_name}* cнял мьют с *#{name}*" if unmute
    "*#{user.full_name}* замьютил *#{name}* на #{distance_of_time_in_words(Time.current, until_time)}"
  end
end