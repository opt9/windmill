class AddUserIdToApikeys < ActiveRecord::Migration
  def change
    add_column :api_keys, :user, :string
  end
end
