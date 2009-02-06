class AddDisplayOrder < Sequel::Migration
  def down
    drop_column(:pages, :display_order)
  end

  def up
    add_column(:pages, :display_order, :integer, :null => false, :default => 1)
  end
end
