require 'rubygems'
require 'json'
require 'parseconfig'
require 'pp'
require 'rest_client'
require 'openshift/routing/controllers/load_balancer'

module OpenShift

  # == Asynchronous Load Balancer Controller
  #
  # Controller for a load balancer that implements an asynchronous API.  On
  # initalization, the object queries the configured load balancer to ascertain
  # existing pools and build a table of Pool objects.
  #
  class AsyncLoadBalancerController < LoadBalancerController

    # == Pool object
    #
    # Represents a pool.  On initialization, the object queries the load
    # balancer using the LoadBalancerController object provided as lb_controller
    # to obtain the members of the pool named by pool_name.  These pool members
    # are stored in @members using one string of the form address:port to
    # represent each pool member.
    #
    # The initializer can optionally be passed false for its fourth
    # argument to prevent it from querying the load balancer for the
    # members of the pool.  It may be desirable to suppress the request
    # when the pool has only just been created on the load balancer.
    #
    class Pool < LoadBalancerController::Pool
      def initialize lb_controller, lb_model, pool_name, request_members=true
        @lb_controller, @lb_model, @name = lb_controller, lb_model, pool_name

        # If we are not supposed to request members, set @members to an empty
        # array now.  If we are supposed to request members, leave @members nil
        # for now so that the members method will initialize it.
        @members = Array.new unless request_members
        @aliases = @lb_model.get_pool_aliases pool_name
      end

      def members
        @members ||= @lb_model.get_pool_members @name
      end

      # Add a member to the object's internal list of members.  This
      # method does not update the load balancer; use the update method
      # of AsyncLoadBalancerController to send the updated list of pool
      # members to the load balancer.
      def add_member address, port
        member = address + ':' + port.to_s

        raise LBControllerException.new "Adding gear #{member} to pool #{@name}, of which the gear is already a member" if members.include? member

        # :add_pool_member blocks
        # if the corresponding pool is being created,
        # if the pool member being added is the same as one that is being deleted, or
        # if the pool member being added is the same as one that is being added
        #   (which can be the case if the same pool member is being added,
        #   deleted, and added again).
        @lb_controller.queue_op Operation.new(:add_pool_member, [self.name, address, port.to_s]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_member, :delete_pool_member].include?(op.type) && op.operands[0] == self.name && op.operands[1] == address && op.operands[2] == port.to_s)}

        members.push member
      end

      # Remove a member from the object's internal list of members.
      # This method does not update the load balancer; use the update
      # method of AsyncLoadBalancerController to force an update.
      def delete_member address, port
        member = address + ':' + port.to_s

        raise LBControllerException.new "Deleting gear #{member} from pool #{@name}, of which the gear is not a member" unless members.include? member

        # :delete_pool_member blocks
        # if the corresponding pool is being created,
        # if the pool member being deleted is the same as one that is being added, or
        # if the pool member being deleted is the same as one that is being deleted
        #   (which can be the case if the same pool member is being added,
        #   deleted, added, and deleted again).
        @lb_controller.queue_op Operation.new(:delete_pool_member, [self.name, address, port.to_s]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_member, :delete_pool_member].include?(op.type) && op.operands[0] == self.name && op.operands[1] == address && op.operands[2] == port.to_s)}

        members.delete member
      end

      def get_aliases
        @aliases
      end

      def add_alias alias_str
        raise LBControllerException.new "Adding alias #{alias_str} to pool #{@name}, which already has the alias" if @aliases.include? alias_str

        # :add_pool_alias blocks
        # if the corresponding pool is being created,
        # if the alias being added is the same as one that is being deleted, or
        # if the alias being added is the same as one that is being added
        #   (which can be the case if the same alias is being added,
        #   deleted, and added again).
        @lb_controller.queue_op Operation.new(:add_pool_alias, [self.name, alias_str]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_alias, :delete_pool_alias].include?(op.type) && op.operands[0] == self.name && op.operands[1] == alias_str)}

        @aliases.push alias_str
      end

      def delete_alias alias_str
        raise LBControllerException.new "Deleting non-existent alias #{alias_str} from pool #{@name}" unless @aliases.include? alias_str

        # :delete_pool_alias blocks
        # if the corresponding pool is being created,
        # if the alias being deleted is the same as one that is being added, or
        # if the alias being deleted is the same as one that is being deleted
        #   (which can be the case if the same alias is being added,
        #   deleted, added, and deleted again).
        @lb_controller.queue_op Operation.new(:delete_pool_alias, [self.name, alias_str]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_alias, :delete_pool_alias].include?(op.type) && op.operands[0] == self.name && op.operands[1] == alias_str)}

        @aliases.delete alias_str
      end

      def add_monitor monitor_name
        # :add_monitor blocks
        # if the corresponding pool is being created,
        # if the monitor being added is the same as one that is being deleted, or
        # if the monitor being added is the same as one that is being added
        #   (which can be the case if the same monitor is being added,
        #   deleted, added, and deleted again).
        @lb_controller.queue_op Operation.new(:add_pool_monitor, [self.name, monitor_name]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_monitor, :delete_pool_monitor].include?(op.type) && op.operands[0] == self.name && op.operands[1] == monitor_name)}
      end

      def delete_monitor monitor_name
        # :add_monitor blocks
        # if the corresponding pool is being created,
        # if the monitor being added is the same as one that is being deleted, or
        # if the monitor being added is the same as one that is being added
        #   (which can be the case if the same monitor is being added,
        #   deleted, added, and deleted again).
        @lb_controller.queue_op Operation.new(:delete_pool_monitor, [self.name, monitor_name]), @lb_controller.ops.select {|op| (op.type == :create_pool && op.operands[0] == self.name) || ([:add_pool_monitor, :delete_pool_monitor].include?(op.type) && op.operands[0] == self.name && op.operands[1] == monitor_name)}
      end

      def get_monitors
        @lb_model.get_pool_monitors @name
      end
    end

    def add_ssl alias_str, ssl_cert, private_key
    end

    def remove_ssl alias_str
    end

    # AsyncLoadBalancerController is designed to be used with a load balancer
    # that provide an asynchronous interface.  Operations such as creating and
    # deleting pools, pool members, and routing rules are submitted to the load
    # balancer, which returns a list of job ids and performs the operations
    # asynchronously.
    #
    # It is our responsibility to ensure that we defer operations that depend on
    # other operations until the load balancer reports that the latter
    # operations are complete.  To that end, we maintain a table of submitted
    # operations, where each Operation corresponds to an operation that is to be
    # or has been submitted to the load balancer.
    #
    # When we are told to carry out an operation, first we check whether it must
    # wait for any Operation in @ops.  We set @blocked_on_cnt of the new
    # Operation to the number of operations on which it must wait, append the
    # new Operation to the @blocked_ops of the corresponding Operation objects,
    # and add the new Operation to @ops.
    #
    # If an Operation has an empty jobids, then it has not been submitted to
    # the load balancer.  If an Operation has non-empty jobids, then it has
    # been submitted to the load balancer and is in progress.
    #
    # If an Operation has not been submitted to the load balancer but has a zero
    # @blocked_on_cnt, then it is ready to be submitted.
    #
    # We periodically submit all ready Operation objects in @ops (i.e., those
    # that have zero @blocked_on_cnt and empty @jobids) to the load balancer.
    # When an operation is submitted, we assign the job ids returned by the load
    # balancer to @jobids of the corresponding Operation objects.
    #
    # We can poll the load balancer using the poll_async_jobs method.  When the
    # load balancer reports that some job has finished, we delete that job from
    # @jobids of the Operation.  If @jobids is empty, then the Operation has
    # completed.
    #
    # When an Operation completes, we check its @blocked_ops attribute,
    # decrement the @blocked_on_cnt for each Operation therein, and delete the
    # completed Operation from @ops.
    #
    # Although we try to ensure that a given operation is not submitted to the
    # load balancer before the load balancer has completed all operations on
    # which the first operation depends, we do not necessarily handle
    # out-of-order events.  
    # Because we only ever make a new Operation block on existing Operation
    # objects, deadlocks are not possible.

    # Symbol, [Object], [String], [Operation], Integer
    # XXX: All instances of Operation have a pool name (String) as the first
    # operand; it might be clearer to move this operand into a new unique
    # field of Operand.
    class Operation < Struct.new :type, :operands, :blocked_on_cnt, :jobids, :blocked_ops
      def to_s
        "#{type}(#{operands.map {|operand| operand.inspect}.join ', '})"
      end
    end

    attr_reader :ops # [Operation]

    # Set the @blocked_on_cnt of the given Operation to the size of the given
    # Array of Operations, add the Operation to @blocked_ops of each of those
    # operations, and finally add the Operation to @ops.
    #
    # Users of queue_op are responsible for computing the Array of Operations
    # that block the new Operation.  It is good practice to document how this
    # Array is computed for each invocation of queue_op.
    def queue_op newop, blocking_ops
      raise LBControllerException.new 'Got an operation with no type' unless newop.type
      newop.operands ||= []
      newop.blocked_on_cnt = blocking_ops.count
      newop.jobids ||= []
      newop.blocked_ops ||= []
      blocking_ops.each {|op| op.blocked_ops.push newop}
      @ops.push newop
    end

    def reap_op op
      op.blocked_ops.each {|blocked_op| blocked_op.blocked_on_cnt -= 1}
      @ops.delete op
    end

    def reap_op_if_no_remaining_tasks op
      if op.jobids.empty?
        @logger.info "Deleting completed operation: #{op}."
        reap_op op
      end
    end

    def cancel_op op
      op.blocked_ops.each {|op| cancel_op op}
      @logger.info "Cancelling operation: #{op}."
      @ops.delete op
    end

    # combine_pool_member_ops :: Symbol, [Operation] -> Operation
    #
    # Each Operation in the input has the same type (either :add_pool_member
    # or :delete_pool_member), and it should be a ready op (i.e., blocked_on_cnt
    # should be 0 and jobids should be empty).
    #
    # This method combines these Operation objects into a single Operation
    # object with the given type (which should be either :add_pool_members or
    # :delete_pool_members).  This op's operands is derived from the input
    # Operation objects.  Its blocked_on_cnt is 0, its jobids is empty, and
    # its blocked_ops is derived from the input Operation objects.
    def combine_pool_member_ops type, ops
      # Each Operation in ops has the same operand[0] (the pool name).
      # The operands, blocked_on_cnt, jobids,
      # and blocked_ops fields are constructed by combining those
      # of the :add_pool_member operations.
      Operation.new(type,
        *ops.
          # group_by :: [Operation] -> {String => [Operation]}
          group_by {|op| op.operands[0]}.
            # map :: {Symbol => [Operation]} -> [[String, [[String, String]], [Operation]]]
            map {|pool,ops| [pool, *ops.map {|op| [op.operands.slice(1,2), op.blocked_ops]}.
              # transpose :: [[[String, String], [Operation]]] -> [[[String, String]], [[Operation]]]
              transpose.
              # tap :: flatten [[[String, String]], [[Operation]]] -> [[[String, String]], [Operation]]
              tap {|ops,blocks| break [ops, blocks.flatten(1)]}
              # The * splat operator on the containing map gives us the following:
              # * :: [[[String, String]], [Operation]] -> [[String, String]], [Operation]
              # which goes inside the containing array.
            ]}.
            # map :: [[String, [[String, String]], [Operation]]] -> [[[String, [[String, String]]], [Operation]]]
            map {|pools, members, blocked_ops| [[pools, members], blocked_ops]}.
            # transpose :: [[[String, [[String, String]]], [Operation]]] -> [[[String, [[String, String]]]], [[Operation]]]
            transpose.
            # tap :: [[[String, [[String, String]]]], [[Operation]]] -> [[[String], [[[String, String]]]], [Operation]]
            tap {|x,blocked_ops| break [x.transpose, blocked_ops.flatten]}.
            # tap :: [[[String], [[[String, String]]]], [Operation]] -> [[[String], [[[String, String]]]], 0, [], [Operation]]
            tap {|x,blocked_ops| break [x, 0, [], blocked_ops]}
            # The splat * operator in the containing Operation.new method call
            # gives us the following:
            # * :: [[String], [[[String, String]]]], 0, [], [Operation]
            # which, along with the type, are the arguments to the method.
      )
    end

    # combine_like_ops :: [Operation] -> [Operation]
    def combine_like_ops ops
      ops.
        # group_by :: [Operation] -> {Symbol => [Operation]}
        group_by {|op| op.type}.
        # map :: {Symbol => [Operation]} -> [[Operation]]
        map {|type,ops|
          # Symbol, [Operation] -> [Operation]
          # Each Operation in the input has the same type.
          case type
          when :add_pool_member
            [combine_pool_member_ops(:add_pool_members, ops)]
          when :delete_pool_member
            [combine_pool_member_ops(:delete_pool_members, ops)]
          else
            ops
          end
        }.
        # [[Operation]] -> [Operation]
        flatten 1
    end

    def create_pool pool_name, monitor_name=nil
      raise LBControllerException.new "Pool already exists: #{pool_name}" if pools.include? pool_name

      # :create_pool blocks
      # if the corresponding monitor is being created or
      # if the corresponding pool is being deleted
      #   (which can be the case if the same pool is being added, deleted, and added again).
      #
      # The pool does not depend on any other objects; we must ensure
      # only that we are not creating a pool at the same time that we
      # are deleting pool of the same name.
      queue_op Operation.new(:create_pool, [pool_name, monitor_name]), @ops.select {|op| (op.type == :delete_pool && op.operands[0] == pool_name) || (op.type == :create_monitor && op.operands[0] == monitor_name)}

      pools[pool_name] = Pool.new self, @lb_model, pool_name, false
    end

    def delete_pool pool_name
      raise LBControllerException.new "Pool not found: #{pool_name}" unless pools.include? pool_name

      raise LBControllerException.new "Deleting pool that is already being deleted: #{pool_name}" if @ops.detect {|op| op.type == :delete_pool && op.operands == [pool_name]}

      # :delete_pool blocks
      # if the corresponding pool is being created,
      # if members are being added to the pool,
      # if members are being deleted from the pool,
      # if a monitor is being added to the pool,
      # if a monitor is being deleted from the pool,
      # if an alias is being added to the pool, or
      # if an alias is being deleted from the pool.
      #
      # Hypothetically, it would cause a problem if we were trying to
      # delete a pool that is already being deleted, which can be the
      # case if the same pool is being added, deleted, added, and
      # deleted again.  However, because we block on :create_pool, we
      # will block on the :create_pool event that is blocking on the
      # previous :delete_pool event.
      #
      # Along similar lines checking for :delete_pool_member is sufficient; it
      # is not necessary to check :add_pool_member.
      #
      # The pool is not depended upon on by any other objects besides
      # pool members and pool aliases.
      queue_op Operation.new(:delete_pool, [pool_name]), @ops.select {|op| [:delete_pool_member, :delete_pool_monitor, :delete_pool_alias, :create_pool].include?(op.type) && op.operands[0] == pool_name}

      pools.delete pool_name
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      @logger.debug "Creating monitor #{monitor_name}, #{path}, #{up_code}, #{type}, #{interval}, #{timeout}"
      if monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} already exists in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor already exists: #{monitor_name}" if monitors.include? monitor_name
      end

      # :create_monitor blocks
      # if a monitor of the same name is currently being deleted.
      queue_op Operation.new(:create_monitor, [monitor_name, path, up_code, type, interval, timeout]), @ops.select {|op| op.type == :delete_monitor && op.operands[0] == monitor_name}

      monitors.push monitor_name
    end

    def delete_monitor monitor_name, pool_name, type
      @logger.debug "Deleting monitor #{monitor_name}, #{pool_name}, #{type}"
      unless monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} does not exist in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor not found: #{monitor_name}" unless monitors.include? monitor_name
      end

      # :delete_monitor blocks
      # if the corresponding pool is being deleted (if one is specified) or
      # if the monitor is being created.
      queue_op Operation.new(:delete_monitor, [monitor_name, type]), @ops.select {|op| (op.type == :create_monitor && op.operands[0] == monitor_name) || (pool_name && op.type == :delete_pool && op.operands[0] == pool_name)}

      monitors.delete monitor_name
    end

    # Update the load balancer with any queued updates.
    def update
      # Re-authenticate if needed.
      @lb_model.maybe_reauthenticate if @lb_model.respond_to? :maybe_reauthenticate

      # Check whether any previously submitted operations have completed.
      poll_async_jobs
      # TODO: Consider instead exposing poll_async_jobs for
      # RoutingDaemon to invoke directly.

      # Filter out operations that involve pools that are in the process
      # of being added to the load balancer, as denoted by the existence
      # of job ids associated with such pools, and jobs that are waiting
      # on other jobs.  Note that order is preserved.
      # [Operation] -> [Operation], [Operation]
      ready_ops, @ops = @ops.partition {|op| op.jobids.empty? && op.blocked_on_cnt.zero?}

      # TODO: Delete pairs of Operation objects that cancel out (e.g., an
      # :add_pool_member and a :delete_pool_member operation for the same
      # member, when neither operation has been submitted or blocks another
      # operation).

      # Combine similar operations, such as two :add_pool_member
      # operations that affect the same pool.
      ready_ops = combine_like_ops ready_ops

      # Put these combined ops back into @ops so we can track them after
      # we have submitted them.
      @ops = @ops + ready_ops

      # Submit ready operations to the load balancer.
      ready_ops.each do |op|
        begin
          @logger.info "Submitting operation to load balancer: #{op}."
          op.jobids = @lb_model.send op.type, *op.operands
          @logger.info "Got back jobids #{op.jobids.join ', '}."

          # In case the operation generates no jobs and is immediately done, we
          # must reap it now because there will be no completion of a job to
          # trigger the reaping.
          reap_op_if_no_remaining_tasks op
        rescue => e
          @logger.warn "Got exception: #{e.message}"
          @logger.debug "Backtrace:\n#{e.backtrace.join "\n"}"

          @logger.info "Cancelling the operation and any operations that it blocks..."

          cancel_op op

          @logger.info "Done."
        end
      end

      @lb_model.update if @lb_model.respond_to?(:update)
    end

    # Returns a Hash representing the JSON response from the load balancer.
    def get_job_status id
      @lb_model.get_job_status id
    end

    # Poll the load balancer for completion of submitted jobs and handle any
    # jobs that are completed.
    def poll_async_jobs
      submitted_ops = @ops.select {|op| not op.jobids.empty?}
      # [Operation] -> [Operation]

      jobs = submitted_ops.map {|op| op.jobids.map {|id| [op,id]}}.flatten(1)
      # [Operation] -> [[Operation,String]]

      @logger.info "Polling #{jobs.length} active jobs: #{jobs.map {|op,id| id}.join ', '}" unless jobs.empty?

      jobs.each do |op,id|
        status = @lb_model.get_job_status id
        case status['Tenant_Job_Details']['status']
        when 'PENDING'
          # Nothing to do but wait some more.
        when 'PROCESSING'
          # Nothing to do but wait some more.
        when 'COMPLETED'
          raise LBControllerException.new "Asked for status of job #{id}, load balancer returned status of job #{status['Tenant_Job_Details']['jobId']}" unless id == status['Tenant_Job_Details']['jobId']

          # TODO: validate that status['requestBody'] is consistent with op.

          @logger.info "Load balancer reports job #{id} completed."
          op.jobids.delete id
          reap_op_if_no_remaining_tasks op
        when 'FAILED'
          @logger.warn "Load balancer reports job #{id} failed."
          @logger.info "Following are the job details from the load balancer:\n" + status.pretty_inspect
          @logger.info "Cancelling associated operation and any operations that it blocks..."

          cancel_op op

          @logger.info "Done."
        else
          raise LBControllerException.new "Got unknown status #{status['Tenant_Job_Details']['status']} for job #{id}."
        end
      end
    end

    # If a pool has been created or is being created in the load balancer, it will be in pools.
    def pools
      @pools ||= begin
        @logger.info "Requesting list of pools from load balancer..."
        Hash[@lb_model.get_pool_names.map {|pool_name| [pool_name, Pool.new(self, @lb_model, pool_name)]}]
      end
    end

    # If a monitor is already created or is being created in the load balancer, it will be in monitors.
    def monitors
      @monitors ||= begin
        @logger.info "Requesting list of monitors from load balancer..."
        @lb_model.get_monitor_names
      end
    end

    def initialize lb_model_class, logger, cfgfile
      @logger = logger

      @logger.info 'Initializing asynchronous controller...'

      @lb_model = lb_model_class.new @logger, cfgfile

      @lb_model.authenticate

      # If an Operation has been created but not yet completed (whether
      # because it is blocked on one or more other Operations, because
      # it has not been submitted to the load balancer, or because it
      # has been submitted but the load balancer has not yet reported
      # completion), it will be in @ops.
      @ops = []

      # Leave @pools and @monitors nil for now and let the
      # methods of the same respective names initialize them lazily.
    end
  end

end
