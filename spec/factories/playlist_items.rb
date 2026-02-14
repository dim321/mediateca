FactoryBot.define do
  factory :playlist_item do
    playlist
    media_file
    position { 1 }
  end
end
