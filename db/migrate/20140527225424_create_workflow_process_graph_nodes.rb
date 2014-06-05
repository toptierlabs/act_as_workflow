class CreateWorkflowProcessGraphNodes < ActiveRecord::Migration
  def change
    create_table :workflow_process_graph_nodes do |t|
      t.references :process_version, index: true
      t.integer :priority
      t.string :owner
      t.boolean :complete_globally
      t.string :when_complete_invalidate_nodes

      t.string :name
      t.text :description
      t.string :url
      t.string :url_text
      t.string :img_url
      t.string :fail_text
      t.string :more_info
      t.string :more_info_text

      t.timestamps
    end
  end
end
