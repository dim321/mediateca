FactoryBot.define do
  factory :playlist_item do
    playlist
    media_file { association(:media_file, user: playlist.user) }
    position { 1 }
  end
end
