class AddUsernameAndAccountIdToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :username, :string
    add_column :accounts, :account_id, :string
  end
end
