class CreateWorkflowProcessInstanceEdges < ActiveRecord::Migration
  def change
    create_table :workflow_process_instance_edges do |t|
      t.references :process_instance_node
      t.references :end_instance_node, index: true
      t.references :process_graph_edge, index: true

      t.timestamps
    end
  end
end
