class CreateWorkflowProcesses < ActiveRecord::Migration
  def change
    create_table :workflow_processes do |t|
      t.string :name
      t.string :entity_class

      t.timestamps
    end
  end
end
