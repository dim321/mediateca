FactoryBot.define do
  factory :media_file do
    user
    title { Faker::Lorem.sentence(word_count: 3) }
    media_type { :audio }
    format { "mp3" }
    file_size { 5.megabytes }
    processing_status { :pending }

    trait :audio do
      media_type { :audio }
      format { %w[mp3 aac wav].sample }
    end

    trait :video do
      media_type { :video }
      format { %w[mp4 avi mov].sample }
    end

    trait :pending do
      processing_status { :pending }
    end

    trait :processing do
      processing_status { :processing }
    end

    trait :ready do
      processing_status { :ready }
      duration { rand(30..600) }
    end

    trait :failed do
      processing_status { :failed }
    end

    trait :with_file do
      after(:build) do |media_file|
        media_file.file.attach(
          io: StringIO.new("fake audio content"),
          filename: "test.#{media_file.format}",
          content_type: media_file.audio? ? "audio/mpeg" : "video/mp4"
        )
      end
    end
  end
end
