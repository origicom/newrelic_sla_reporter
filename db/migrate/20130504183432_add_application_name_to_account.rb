class AddApplicationNameToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :application_name, :string
  end
end
