FactoryBot.define do
  factory :auction do
    time_slot
    starting_price { 100.00 }
    closes_at { 1.hour.from_now }
    auction_status { :open }

    trait :open do
      auction_status { :open }
    end

    trait :closed do
      auction_status { :closed }
      closes_at { 1.hour.ago }
    end

    trait :cancelled do
      auction_status { :cancelled }
    end

    trait :with_bids do
      after(:create) do |auction|
        user = create(:user)
        create(:financial_account, user: user, available_amount_cents: 1_000_000, held_amount_cents: 0)
        create(:bid, auction: auction, user: user, amount: auction.starting_price + 100)
      end
    end
  end
end
