class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include ActionView::Helpers::DateHelper

  def message(message)
    response = '';
    user = User.handle_user(message['from'])
    user.update_columns(last_message_at: Time.current)
    reputation_words = Config.
      where(key: ['reputation_increase_words', 'reputation_decrease_words']).
      pluck(:value).
      join(',').
      split(',').
      map{|w| w.downcase.strip}
    check_for_achievements = false
    response = if message['new_chat_participant'].present?
      new_user = User.handle_user(message['new_chat_participant'])
      new_user.update(status: :active)
      msg = Message.find_by(slug: 'welcome')
      return unless msg.present?
      response = msg.interpolate({first_name: User.get_full_name(message['new_chat_participant'])})
      Message.add_image(response, :drink)
    elsif message['left_chat_participant'].present?
      user_left = User.handle_user(message['left_chat_participant'])
      user_left.update(status: :left)
      nil
    elsif message['text'].present? && message['text'] == '!kick'
      kick_or_ban(message, false)
    elsif message['text'].present? && message['text'] == '!ban'
      kick_or_ban(message, true)
    elsif message['text'].present? && message['text'].include?('!mute')
      mute_or_unmute(message, false)
    elsif message['text'].present? && message['text'].include?('!unmute')
      mute_or_unmute(message, true)
    elsif message['text'].present? && message['text'].include?('!warn')
      warn(message)
    elsif message['text'].present? && message['text'].include?('!pin')
      pin(message, true)
    elsif message['text'].present? && reputation_words.map{|w| message['text'].downcase.include?(w)}.any?
      reputation(message)
    elsif message['text'].present?
      Book.detect_book_mention(message['text'])
    elsif message['photo'].present?
      response = Drink.handle_drink(user, message)
      check_for_achievements = response.present?
      response
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
    respond_with :message, text: "*100% Спирт*: #{user.drink_score.to_i} мл (всего #{drink_score.to_i} мл)\n*Законченные книги*: #{user.book_score.to_i} (всего #{book_score.to_i})\n*Репутация*: #{user.reputation}", parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def set_untappd_username!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    user.update(untappd_username: data, untappd_synced_at: Time.current - 1.hour) if data.present? && User.where(untappd_username: data).empty?
    response = if user.untappd_username.present?
      "Для #{user.full_name_or_username} включена синхронизация с untappd по юзернейму #{user.untappd_username}"
    else
      "Невозможно включить синхронизацию с untappd для #{data}"
    end
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def sync_untappd!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    if !user.untappd_username.present?
      response = "Для #{user.full_name_or_username} не включена синхронизация с untappd"
      respond_with :message, text: response, parse_mode: :Markdown
      return
    end
    if user.untappd_synced_at > Time.current - 10.minutes
      response = "Синхронизация с untappd возможна раз в 10 минут"
      respond_with :message, text: response, parse_mode: :Markdown
      return
    end
    responses = Drink.sync_untappd(user)
    if responses.empty?
      respond_with :message, text: "Не найдено новых чекинов в untappd", parse_mode: :Markdown
    else
      responses.each do |response|
        respond_with :message, text: response, parse_mode: :Markdown
      end
    end
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def run!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    drinks_count = user.drinks.count
    books_count = user.drinks.count
    response = if drinks_count <= 0 || books_count <= 0
      "Для того, чтобы баллотироваться в президенты Бухотеки нужно и пить, и читать! Выпей бухла и прочитай книгу!"
    else
      user.update(run: true)
      participants = User.where(run: true)
      "#{user.full_name_or_username} баллотируется на пост президента Бухотеки!\n\nВ выборах участвуют:\n#{participants.map{|u| "\u2022 #{u.full_name_or_username}"}.join("\n")}"
    end
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def unrun!(data = nil, *)
    user = User.handle_user(from)
    return unless user.present?
    response = if user.run
      user.update(run: false)
      participants = User.where(run: true)
      "#{user.full_name_or_username} снимает свою кандидатуру с выборов президента Бухотеки!\n\nВ выборах участвуют:\n#{participants.map{|u| "\u2022 #{u.full_name_or_username}"}.join("\n")}"
    else
      "Вы и так не участвуете в выборах президента Бухотеки."
    end
    respond_with :message, text: response, parse_mode: :Markdown
  rescue Exception => e
    puts "Error in command handler".red
    puts e.message
  end

  def elections!(data = nil, *)
    participants = User.where(run: true)
    response = if participants.count > 0
      "В выборах участвуют:\n#{participants.map{|u| "\u2022 #{u.full_name_or_username}"}.join("\n")}"
    else
      "Никто не выдвигал свою кандидатуру на выборы"
    end
    respond_with :message, text: response, parse_mode: :Markdown
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
    target_user = User.find_by(telegram_id: user_id)
    target_user.update(status: ban ? :banned : :kicked)
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

  def pin(message, notify = true)
    user = User.handle_user(message['from'])
    if user.last_pinned_at.present? && user.last_pinned_at > Time.current - 12.hours
      return "Закрепить сообщение можно раз в 12 часов"
    end
    reply = message['reply_to_message']
    return unless reply.present?
    reply_id = reply['message_id']
    chat_id = Rails.application.credentials.telegram[:bot][:chat_id].to_i
    Telegram.bot.pin_chat_message(chat_id: chat_id, message_id: reply_id, disable_notification: !notify)
    user.update(last_pinned_at: Time.current)
    nil
  end

  def reputation(message)
    user = User.handle_user(message['from'])
    reputation_user = begin User.handle_user(message['reply_to_message']['from']) rescue nil end
    return unless user.present? && reputation_user.present? && user.id != reputation_user.id
    reputation_increase_words = Config.find_by(key: 'reputation_increase_words').
      value.
      split(',').
      map{|w| w.downcase.strip}
    reputation_decrease_words = Config.find_by(key: 'reputation_decrease_words').
      value.
      split(',').
      map{|w| w.downcase.strip}
    text = message['text'].downcase
    reputation = reputation_user.reputation
    message = if reputation_increase_words.map{|w| text.include?(w)}.any?
      reputation += 1
      Message.find_by(slug: 'reputation_increase')
    elsif reputation_decrease_words.map{|w| text.include?(w)}.any?
      reputation -= 1
      reputation = 0 if reputation < 0
      Message.find_by(slug: 'reputation_decrease')
    else
      nil
    end
    return nil unless message.present?
    reputation_user.update(reputation: reputation)
    response = message.interpolate({
      first: "[#{user.full_name_or_username}](tg://user?id=#{user.id})",
      second: "[#{reputation_user.full_name_or_username}](tg://user?id=#{reputation_user.id})",
      reputation: reputation
    })
  end

  def warn(message)
    user = User.handle_user(message['from'])
    return unless user.present? && user.admin.present?
    cannot_kick_usernames = Admin.where.not(user_id: nil).includes(:user).pluck(:username).concat([Rails.application.credentials.telegram[:bot][:username]])
    message_from = message['reply_to_message']['from']
    user_id, name = if message_from.present? && !cannot_kick_usernames.include?(message_from['username'])
      [message_from['id'], [message_from['first_name'], message_from['last_name']].join(' ')]
    end
    warned_user = User.find_by(telegram_id: user_id)
    return "Не могу выдать пользователю warn" unless user_id.present?
    warned_user.update(warns: user.warns + 1)
    warns_limit = Config.find_by(key: 'warns_limit').value.to_i
    response = ''
    if user.warns >= warns_limit
      warned_user.update(warns: 0)
      until_date = (Time.current + 1.minute).to_i
      Telegram.bot.kick_chat_member({
        chat_id: Rails.application.credentials.telegram[:bot][:chat_id].to_i,
        user_id: user_id,
        until_date: until_date
      })
      return "#{name} получил #{warns_limit} предупреждений и был кикнут"
    end
    "#{name} получил #{warned_user.warns} предупреждений из #{warns_limit}"
  end
end