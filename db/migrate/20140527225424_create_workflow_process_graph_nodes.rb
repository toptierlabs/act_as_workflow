class CreateWorkflowProcessGraphNodes < ActiveRecord::Migration
  def change
    create_table :workflow_process_graph_nodes do |t|
      t.references :process_version, index: true
      t.integer :priority
      t.string :owner
      t.boolean :complete_globally
      t.integer :when_complete_invalidate_nodes

      t.timestamps
    end
  end
end
