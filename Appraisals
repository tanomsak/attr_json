appraise "rails-5-0" do
  gem 'combustion', '~> 0.9.0'

  gem "rails", "~> 5.0.0"

  # rails 5.1+ includes it by default, but rails 5.0 needs it:
  gem 'rails-ujs', require: false

  # Rails 5 won't work with pg 1.0 even though it doesn't say so
  gem "pg",  "~> 0.18"
end

appraise "rails-5-1" do
  gem 'combustion', '~> 0.9.0'

  gem "rails", "~> 5.1.0"

  gem "pg", "~> 1.0"
end

appraise "rails-5-2" do
  gem 'combustion', '~> 0.9.0'

  gem "rails", "~> 5.2.0"
  gem "pg", "~> 1.0"
end

appraise "rails-6-0" do
  gem 'combustion', git: "https://github.com/pat/combustion.git"

  gem "rails", ">= 6.0.0.beta1", "< 6.1"
  gem "pg", "~> 1.0"
end

appraise "rails-edge-6" do
  # Edge rails needs unreleased combustion
  # https://github.com/pat/combustion/issues/92
  gem 'combustion', git: "https://github.com/pat/combustion.git"

  gem "rails", git: "https://github.com/rails/rails.git", branch: "master"
  gem "pg", "~> 1.0"

  # We don't actually use coffeescript at all, we need coffee-rails as an explicit
  # dependency just for transitory edge weirdness using current sprockets release
  # with rails 6 edge.
  gem 'coffee-rails'
end
