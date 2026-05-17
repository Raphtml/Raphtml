class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :athlete,               null: false, foreign_key: true
      t.bigint     :strava_id,             null: false
      t.string     :name
      t.string     :activity_type
      t.datetime   :start_date
      t.datetime   :start_date_local
      t.string     :timezone
      t.integer    :moving_time
      t.integer    :elapsed_time
      t.float      :distance
      t.float      :total_elevation_gain
      t.integer    :average_watts
      t.integer    :weighted_average_watts
      t.integer    :max_watts
      t.float      :average_heartrate
      t.float      :average_speed
      t.integer    :suffer_score
      t.float      :tss
      t.boolean    :trainer,               default: false

      t.timestamps
    end

    add_index :activities, :strava_id, unique: true
    add_index :activities, [ :athlete_id, :start_date_local ]
  end
end
