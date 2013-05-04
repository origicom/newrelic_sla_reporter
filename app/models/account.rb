class Account < ActiveRecord::Base
  attr_accessible :api_key, :name, :username, :account_id, :application_id, :application_name
end
