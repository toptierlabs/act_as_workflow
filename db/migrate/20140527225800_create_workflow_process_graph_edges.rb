class CreateWorkflowProcessGraphEdges < ActiveRecord::Migration
  def change
    create_table :workflow_process_graph_edges do |t|
      t.references :workflow_process_graph_node, index: true
      t.integer :end_node

      t.timestamps
    end
  end
end
