module Workflow
  class Process < ActiveRecord::Base
    has_many :process_versions

    delegate :find_version_instances_for, to: :process_versions

  end
end
