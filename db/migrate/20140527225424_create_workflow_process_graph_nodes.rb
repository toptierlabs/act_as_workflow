class CreateWorkflowProcessGraphNodes < ActiveRecord::Migration
  def change
    create_table :workflow_process_graph_nodes do |t|
      t.references :workflow_process_version, index: true
      t.integer :priority
      t.integer :owner
      t.integer :when_complete_invalidate_nodes

      t.timestamps
    end
  end
end
