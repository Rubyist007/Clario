class Subscription < ApplicationRecord
  enum :status, %i[inactive active]
end
