class CreateProjects < ActiveRecord::Migration[5.1]
  def change
    create_table :projects do |t|
      t.string :name, :null => false, :default => ""
      t.string :description, :null => false, :default => ""
      t.references :company, foreign_key: true
      t.integer :reviews_count, :null => false, :default => 0

      t.index :reviews_count
      t.timestamps
    end
    add_column :projects, :discarded_at, :datetime
    add_index :projects, :discarded_at
  end
end
