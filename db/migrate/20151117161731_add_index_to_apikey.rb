class AddIndexToApikey < ActiveRecord::Migration
  def change
    add_index :api_keys, :key
  end
end
