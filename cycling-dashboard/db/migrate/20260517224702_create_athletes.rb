class CreateAthletes < ActiveRecord::Migration[8.1]
  def change
    create_table :athletes do |t|
      t.string :strava_id
      t.string :firstname
      t.string :lastname
      t.string :profile_medium
      t.string :access_token
      t.string :refresh_token
      t.integer :token_expires_at
      t.integer :ftp

      t.timestamps
    end
    add_index :athletes, :strava_id, unique: true
  end
end
