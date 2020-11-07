namespace :restore do
  desc "Restore history"
  task drinks: :environment do
    user = User.find(1)
    messages = JSON.parse(File.open("lib/assets/result.json").read)
    drink_messages = messages["messages"].select{|m| m["type"] == 'message' && m["from"] == 'Triod' && begin m['text'][0]['text'].include?('#') && !m['text'][0]['text'].include?('https') rescue false end}.map{|m| {text: m['text'].map{|t| t['text']}.join(' '), date: Time.parse(m['date'])}}
    drink_messages.each do |msg|
      payload = msg[:text]
      time = msg[:date]
      tags = payload.split('#').map(&:strip).filter{|t| t.present?}.map(&:downcase)
      next unless tags.present?
      drink = Drink.where(name: tags).first
      unless drink.present?
        puts "No such drink #{tags.join(',')}"
        next
      end
      abv = Drink.handle_abv(tags)
      volume = Drink.handle_volume(tags)
      incorrect_abv = !abv.present? || abv.present? && (abv <= 0 || abv > 100)
      incorrect_volume = !volume.present? || volume.present? && (volume <= 0 || volume >= 10000)
      if incorrect_abv || incorrect_volume
        puts "Incorrect volume or alcohol"
        next
      end
      DrinksUser.create(user: user, drink: drink, abv: abv, volume: volume, file_id: nil, created_at: time)
      puts "Добавлено #{drink.name.gsub(/_/, ' ')} #{abv || '0'}% #{volume.to_i || '0'} мл"
    end
    user.recalculate_scores
  end

  task books: :environment do
    user = User.find(1)
    messages = JSON.parse(File.open("lib/assets/result.json").read)
    book_messages = messages["messages"].select{|m| m["type"] == 'message' && m["from"] == 'Triod' && begin m['text'][0]['text'].include?('/finish_book') rescue false end}.map{|m| {text: begin m['text'][2]['text'] rescue nil end, date: m['date']}}
    book_messages.map do |msg|
      payload = msg[:text]
      time = msg[:date]
      next unless payload.present?
      book = Book.extract_book(payload)
      next unless book.present?
      BooksUser.create(book_id: book.id, user_id: user.id, finished: true, created_at: time)
    end
    user.recalculate_scores
  end
end