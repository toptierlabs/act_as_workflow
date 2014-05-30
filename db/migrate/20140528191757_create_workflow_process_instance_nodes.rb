class CreateWorkflowProcessInstanceNodes < ActiveRecord::Migration
  def change
    create_table :workflow_process_instance_nodes do |t|
      t.references :process_instance, index: true
      t.references :process_graph_node, index: true
      t.datetime :completed_at
      t.datetime :canceled_at

      t.timestamps
    end
  end
end
