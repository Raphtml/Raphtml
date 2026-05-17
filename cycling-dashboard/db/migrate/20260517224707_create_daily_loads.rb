class CreateDailyLoads < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_loads do |t|
      t.references :athlete, null: false, foreign_key: true
      t.date       :date,    null: false
      t.float      :tss,     default: 0.0
      t.float      :ctl,     default: 0.0
      t.float      :atl,     default: 0.0
      t.float      :tsb,     default: 0.0

      t.timestamps
    end

    add_index :daily_loads, [ :athlete_id, :date ], unique: true
  end
end
