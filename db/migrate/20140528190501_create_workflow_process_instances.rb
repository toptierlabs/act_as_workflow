class CreateWorkflowProcessInstances < ActiveRecord::Migration
  def change
    create_table :workflow_process_instances do |t|
      t.references :process_version, index: true
      t.references :entity, polymorphic: true, index: true
      t.references :user, index: true
      t.references :dummy_instance_node, index: true
      t.string :role

      t.timestamps
    end
  end
end
