# frozen_string_literal: true

puts "Seeding database..."

# Admin user
admin = User.find_or_create_by!(email: "admin@mediateca.dev") do |u|
  u.password = "admin123456"
  u.password_confirmation = "admin123456"
  u.first_name = "Admin"
  u.last_name = "Mediateca"
  u.role = :admin
  u.balance = 0
end
puts "  Admin created: #{admin.email}"

# Sample users
users = 3.times.map do |i|
  User.find_or_create_by!(email: "user#{i + 1}@mediateca.dev") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.first_name = %w[Иван Мария Дмитрий][i]
    u.last_name = %w[Петров Сидорова Козлов][i]
    u.role = :user
    u.balance = [5000, 10000, 3000][i]
    u.company_name = ["ООО Реклама Плюс", "ИП Сидорова", nil][i]
  end
end
puts "  #{users.size} users created"

# Broadcast devices
devices = [
  { name: "ТВ-001 Вход", city: "Москва", address: "ул. Тверская, 1", time_zone: "Moscow" },
  { name: "ТВ-002 Зал", city: "Москва", address: "ул. Арбат, 10", time_zone: "Moscow" },
  { name: "ТВ-003 Фудкорт", city: "Санкт-Петербург", address: "Невский пр., 50", time_zone: "Moscow" },
  { name: "ТВ-004 Лобби", city: "Екатеринбург", address: "ул. Ленина, 5", time_zone: "Ekaterinburg" }
].map do |attrs|
  BroadcastDevice.find_or_create_by!(name: attrs[:name]) do |d|
    d.city = attrs[:city]
    d.address = attrs[:address]
    d.time_zone = attrs[:time_zone]
    d.status = :online
  end
end
puts "  #{devices.size} devices created"

# Device groups
groups = ["Торговые центры", "Бизнес-центры"].map do |name|
  DeviceGroup.find_or_create_by!(name: name)
end
groups.first.broadcast_devices << devices[0..1] rescue nil
groups.last.broadcast_devices << devices[2..3] rescue nil
puts "  #{groups.size} device groups created"

# Time slots for tomorrow
tomorrow = Date.tomorrow
devices.each do |device|
  zone = ActiveSupport::TimeZone[device.time_zone] || ActiveSupport::TimeZone["UTC"]
  day_start = zone.local(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0) # 8 AM local
  next if device.time_slots.for_date(tomorrow).any?

  16.times do |i| # 8 hours of slots (8 AM - 4 PM)
    start_time = day_start + (i * 30).minutes
    TimeSlot.create!(
      broadcast_device: device,
      start_time: start_time.utc,
      end_time: (start_time + 30.minutes).utc,
      starting_price: [100, 200, 500, 300].sample,
      slot_status: :available
    )
  end
end
puts "  Time slots created for #{tomorrow}"

# Sample auctions for first device
available_slots = devices.first.time_slots.available.limit(3)
available_slots.each_with_index do |slot, i|
  Auction.find_or_create_by!(time_slot: slot) do |a|
    a.starting_price = slot.starting_price > 0 ? slot.starting_price : 100
    a.closes_at = slot.start_time - 1.hour
    a.auction_status = :open
  end
  slot.update!(slot_status: :auction_active)
end
puts "  #{available_slots.size} auctions created"

puts "Seeding complete!"
