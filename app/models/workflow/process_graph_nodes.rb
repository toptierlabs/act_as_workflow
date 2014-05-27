module Workflow
  class ProcessGraphNodes < ActiveRecord::Base
    belongs_to :process_version
  end
end
