# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

[
  {name: 'День прошёл не зря', slug: 'good_day', description: 'Выпить минимум один раз за день'},
  {name: 'Читать и бухать лучше одновременно', slug: 'drink_and_read', description: 'Прочитать книгу и выпить в один день'},
  {name: 'Ни шагу назад!', slug: 'non_stop', description: 'Выпить за день больше 3 раз'},
].each do |achievement|
  Achievement.where(name: achievement[:name]).first_or_create(description: achievement[:description])
end

%w(
  https://derpicdn.net/img/2019/12/13/2219723/large.png
  https://derpicdn.net/img/view/2019/11/13/2194487.png
  https://derpicdn.net/img/view/2020/7/26/2407989.png
  https://derpicdn.net/img/2020/7/7/2392984/large.jpg
  https://derpicdn.net/img/view/2018/10/17/1859022.png
  https://derpicdn.net/img/2020/9/8/2440672/large.png
  https://derpicdn.net/img/2020/8/21/2427826/large.png
  https://derpicdn.net/img/2020/8/18/2426019/large.jpg
  https://derpicdn.net/img/2020/8/15/2423769/large.jpg
  https://derpicdn.net/img/2020/8/12/2421554/large.png
  https://derpicdn.net/img/view/2020/6/24/2382580.jpg
  https://derpicdn.net/img/view/2020/6/8/2369648.png
  https://derpicdn.net/img/2020/4/15/2323542/large.jpg
  https://derpicdn.net/img/2020/4/1/2311471/large.jpg
  https://derpicdn.net/img/view/2020/3/28/2307862.jpg
  https://derpicdn.net/img/view/2020/1/31/2261563.png
).each do |url|
  Image.where(url: url).first_or_create
end

Message.where(slug: 'rules').first_or_create(content: Base64.decode64("0JPQvtC70L7RgdC+0LLRi9C1INGB0L7QvtCx0YnQtdC90LjRjyDQvdC1INC+\n0LTQvtCx0YDRj9GO0YLRgdGPDQoNCtCU0LvRjyDQtNC40YfQuCwg0L/QvtGA\n0L3Rg9GF0Lgg0Lgg0LHQtdGB0YHQvNGL0YHQu9C10L3QvdC+0LPQviDRhNC7\n0YPQtNCwINGB0YLQuNC60LXRgNCw0LzQuCDQtdGB0YLRjCDQtNGA0YPQs9C4\n0LUg0YfQsNGC0YsNCg0K0JHQvtGCINC00LXRgtC10LrRgtC40YIg0L7RgdC9\n0L7QstC90YvQtSDQutC90LjQttC90YvQtSDRgdCw0YLRiyDQstGA0L7QtNC1\nIGZpbWZpY3Rpb24sIGZpY2Jvb2ssIGxpdmVsaWIg0Lgg0L/RgNC10LTQu9Cw\n0LPQsNC10YIg0LTQvtCx0LDQstC40YLRjCDQutC90LjQs9GDINCyINC/0YDQ\nvtGH0LjRgtCw0L3QvdC+0LUuDQrQndC1INGB0YTQvtGC0LrQsNC7IC0g0L3Q\ntSDQstGL0L/QuNC7LiDQo9GH0ZHRgiDQsNC70LrQvtCz0L7Qu9GPINCy0LXQ\ntNGR0YLRgdGPINGH0LXRgNC10Lcg0LrQsNGA0YLQuNC90LrQuCDRgSDRgtC1\n0LPQsNC80LguDQoNCtCa0L7QvNCw0L3QtNGLINCx0L7RgtCwOg0KL3JvbGwg\nLSDQvtGC0LLQtdGCINC90LAg0LLQvtC/0YDQvtGBICLQv9C40YLRjCDQuNC7\n0Lgg0L3QtSDQv9C40YLRjD8iDQovcnVsZXMgLSDRjdGC0Lgg0L/RgNCw0LLQ\nuNC70LANCi9oYXNfZHJpbmsg0L3QsNC30LLQsNC90LjQtV/QvdCw0L/QuNGC\n0LrQsCAtINGD0LfQvdCw0YLRjCwg0LXRgdGC0Ywg0LvQuCDQvdCw0L/QuNGC\n0L7QuiDQsiDQsdCw0LfQtQ0KL2FkZF9kcmluayDQvdCw0LfQstCw0L3QuNC1\nX9C90LDQv9C40YLQutCwIC0g0LTQvtCx0LDQstC40YLRjCDQvdCw0L/QuNGC\n0L7QuiDQsiDQsdCw0LfRgw0KL2FkZF9ib29rINGB0YHRi9C70LrQsF/QvdCw\nX9C60L3QuNCz0YMgLSDQtNC+0LHQsNCy0LjRgtGMINC60L3QuNCz0YMg0LIg\n0L/RgNC+0YfQuNGC0LDQvdC90L7QtQ0KL3RvcF9ib29rcyAtINGC0L7QvyDQ\nutC90LjQsw0KL3RvcF9yZWFkZXJzIC0g0YLQvtC/INGH0LjRgtCw0YLQtdC7\n0LXQuQ0KL3RvcF9kcmlua3MgLSDRgtC+0L8g0LHRg9GF0LvQsA0KL3RvcF9k\ncmlua2VycyAtINGC0L7QvyDQsNC70LrQvtCz0L7Qu9C40LrQvtCy\n"))
Message.where(slug: 'welcome').first_or_create(content: Base64.decode64("0JTQvtCx0YDQviDQv9C+0LbQsNC70L7QstCw0YLRjCDQsiDQkdGD0YXQvtGC\n0LXQutGDINCc0Y3QudC90YXRjdGC0YLQtdC90LAsICole2ZpcnN0X25hbWV9\nKiEKCtCjINC90LDRgSDQvNC+0LbQvdC+ICjQuCDQvdGD0LbQvdC+KSDQvtCx\n0YHRg9C20LTQsNGC0Ywg0LrQvdC40LPQuCDQuCDQsNC70LrQvtCz0L7Qu9GM\nLgrQndCw0LbQvNC40YLQtSAvcnVsZXMg0YfRgtC+0LHRiyDQv9C+0LvRg9GH\n0LjRgtGMINGB0L/RgNCw0LLQutGDINC/0L4g0LHQvtGC0YMsINC+0L0g0YPQ\nvNC10LXRgiDQvNC90L7Qs9C+INC/0L7Qu9C10LfQvdGL0YUg0YjRgtGD0Loh\n"))
Message.where(slug: 'achievement').first_or_create(content: "*%{full_name}* получает достижение *%{name}*!\n_%{description}_")
Message.where(slug: 'rank').first_or_create(content: "*%{full_name}* получает новый ранг *%{name}*!")

Config.where(key: 'strong_alcohol_threshold').first_or_create(value: '12')

# Rank.all.map{|r| "{entity: :#{r.entity}, threshold: #{r.threshold}, name: \"#{r.name}\"},"}
[
  {entity: :drink, threshold: 1, name: "Начинающий алкоголик"},
  {entity: :drink, threshold: 10, name: "Ударник алкольного труда"},
  {entity: :drink, threshold: 50, name: "Пьяница"},
  {entity: :drink, threshold: 100, name: "Бог-император"},
  {entity: :book, threshold: 1, name: "Первоклашка"},
  {entity: :book, threshold: 5, name: "Подающий надежды читатель"},
  {entity: :book, threshold: 20, name: "Хэйтер деревьев"},
  {entity: :book, threshold: 100, name: "Твайлайт смотрит на тебя с восторгом!"},
  {entity: :book, threshold: 50, name: "Best book borrower"},
  {entity: :book, threshold: 10, name: "Постоянный посетитель библиотеки"}
].each do |rank|
  Rank.where(name: rank[:name]).first_or_create(entity: rank[:entity], threshold: rank[:threshold])
end

# Achievement.all.map{|a| "{name: \"#{a.name}\", description: \"#{a.description}\", condition: \"#{a.condition}\"},"}
[
  {name: "Ни шагу назад!", description: "Выпить за день больше 3 раз", condition: "drinks_today > 3"},
  {name: "День прошёл не зря", description: "Выпить минимум один раз за день", condition: "drinks_today >= 1"},
  {name: "Читать и бухать лучше одновременно", description: "Читать и пить в один день", condition: "drinks_today >= 1 && books_today >= 1"},
  {name: "Идём на повышение!", description: "Повысить градус как минимум один раз", condition: "abv_relations.include?('+1')"},
  {name: "Идём на понижение!", description: "Понизить градус как минимум один раз", condition: "abv_relations.include?('-1')"},
  {name: "Корейский рандом", description: "Повысить градус после его понижения", condition: "abv_relations.include?('-1,+1') || abv_relations.include?('-1,0,+1')"},
  {name: "Бездонная бочка", description: "Выпить больше двух литров за день", condition: "volume_today >= 2000"},
  {name: "Ударник", description: "Выпить больше 10 раз за неделю", condition: "drinks_this_week >= 10"},
  {name: "Постоянный читатель", description: "Добавить за неделю семь книг в процессе чтения", condition: "books_this_week >= 7"},
  {name: "Любитель догоняться", description: "Выпить меньший объем после большего", condition: "volume_relations.include?('0,-1') || volume_relations.include?('+1,-1')"},
  {name: "Крепкий читатель", description: "Выпить крепкий алкоголь и читать книгу", condition: "abv_sequence.include?('strong') && books_today >= 1"}
].each do |a|
  Achievement.where(name: a[:name]).first_or_create(description: a[:description], condition: a[:condition])
end

Config.where(key: 'chat_id').first_or_create(value: '')
Config.where(key: 'warns_limit').first_or_create(value: '3')
Config.where(key: 'reputation_increase_words').first_or_create(value: "Одобряю, Да благословит тебя Селестия")
Config.where(key: 'reputation_decrease_words').first_or_create(value: "Порицаю, Да проклянёт тебя Луна")
Message.where(slug: 'person_of_a_day').first_or_create(content: "*Человеком дня* сегодня будет %{username}! Поднимем же за него бокалы!")
Message.where(slug: 'drink_buddy').first_or_create(content: "*%{buddy_name}* сегодня пьёт с *%{master_name}*")
Message.where(slug: 'reputation_increase').first_or_create(content: "%{first} увеличил репутацию %{second} до %{reputation}")
Message.where(slug: 'reputation_decrease').first_or_create(content: "%{first} понизил репутацию %{second} до %{reputation}")

[
  {name: "roll", description: "ответ на вечный вопрос 'пить или не пить?'"},
  {name: "rules", description: "прочитать правила"},
  {name: "has_drink", description: "название_напитка - узнать, есть ли напиток в базе"},
  {name: "add_drink", description: "название_напитка - добавить напиток в базу"},
  {name: "add_book", description: "ссылка_на_книгу - добавить книгу в процессе чтения"},
  {name: "finish_book", description: "ссылка_на_книгу - добавить книгу в прочитанное"},
  {name: "top_books", description: "топ книг"},
  {name: "top_readers", description: "топ читателей"},
  {name: "top_drinks", description: "топ бухла"},
  {name: "top_drinkers", description: "топ алкоголиков"},
  {name: "all_achievements", description: "список достижений"},
  {name: "my_achievements", description: "ваши личные достижения"},
  {name: "find_drink_buddy", description: "найти собутыльника"},
].each do |bc|
  BotCommand.where(name: bc[:name]).first_or_create(description: bc[:description])
end