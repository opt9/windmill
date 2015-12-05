class CreateApiKeys < ActiveRecord::Migration
  def self.up
    create_table :api_keys do |t|
      t.string :key, null: false
      t.string :notes
      t.string :perms, null: false
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :apikeys
  end
end
