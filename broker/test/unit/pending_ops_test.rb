require_relative '../test_helper'

class PendingOpsTest < ActiveSupport::TestCase

  setup do 
    @@op_blocks = []
    @random = rand(1000000000)
    @domain = Domain.create(:namespace => "domain#{@random}")
    @team = Team.create(:name => "team#{@random}")
    set_timeouts
  end

  teardown do
    @@op_blocks = []
    @domain.delete
    @team.delete
  end

  ["team", "domain"].each do |type|

    test "multiple #{type} ops run in sequence" do
      # Retry up to 100 times, 1/10 second apart (10 seconds total), make sure the ops run in sequence
      set_timeouts(retries:100, sleep:0.1, timeout:30)

      state = 0

      # Op blocks which take the operation number and the execution number as args
      add_op(type) do |op,run| 
        assert_equal 0, op
        assert_equal 0, run
        assert_equal 0, state
        state = 1
        sleep(0.25)
      end
      add_op(type) do |op,run| 
        assert_equal 1, op
        assert_equal 0, run
        assert_equal 1, state
        state = 2
        sleep(0.25)
      end
      # Allow op blocks that just take the execution number as an arg
      add_op(type) do |run| 
        assert_equal 0, run
        assert_equal 2, state
        state = 3
        sleep(0.25)
      end
      # Allow parameterless op blocks
      add_op(type) do
        assert_equal 3, state
        state = 4
        sleep(0.25)
      end

      20.times do 
        async do 
          assert m = model_class(type).find(model(type).id)
          assert m.run_jobs
        end
      end
      join

      assert_equal [], model(type).reload.pending_ops
      assert_equal 4, state
    end

    test "failed #{type} op gets put back in init state and retried on next run" do
      state = :never_run

      add_op(type) do |run| 
        case run
        when 0
          assert_equal :never_run, state
          state = :failed_first_run
          raise "Error"
        when 1
          assert_equal :failed_first_run, state
          state = :succeeded_second_run
        else
          fail "Run too many times: #{i}"
        end
      end

      assert_raise(RuntimeError) { model(type).run_jobs }
      assert op = model(type).reload.pending_ops.first
      assert_equal :init, op.state
      assert_equal 0, op.queued_at
      assert_equal :failed_first_run, state

      assert model(type).run_jobs
      assert_equal [], model(type).reload.pending_ops
      assert_equal :succeeded_second_run, state
    end

    test "#{type} ops do not get run from multiple threads" do
      # Retry up to 100 times, 1/10 second apart (10 seconds total), make sure only one thread picks up the op
      set_timeouts(retries:100, sleep:0.1, timeout:30)
      state = :never_run
      add_op(type) do |run|
        assert_equal 0, run
        assert_equal :never_run, state
        state = :pre_sleep
        sleep(1)
        assert_equal :pre_sleep, state
        state = :post_sleep
      end

      20.times do 
        async do 
          assert m = model_class(type).find(model(type).id)
          assert m.run_jobs
        end
      end
      join

      assert_equal :post_sleep, state
      assert_equal [], model(type).reload.pending_ops
    end

    test "a running #{type} op blocks later ops" do
      add_op(type, :queued, Time.now.to_i) { fail "Already marked as running, shouldn't get called" }
      add_op(type) { fail "Shouldn't get called, should have been blocked by running op" }

      assert_raise(OpenShift::LockUnavailableException) { model(type).reload.run_jobs }
      assert_equal [:queued, :init], model(type).reload.pending_ops.map(&:state)
    end

    test "a timed out #{type} op gets retried" do
      # Retry up to 100 times, 1/10 second apart (10 seconds total), should pick up the timed-out op a few seconds in
      set_timeouts(retries:100, sleep:0.1, timeout:2)

      state = :never_run

      add_op(type, :queued, Time.now.to_i) do |run|
        assert_equal 0, run
        assert_equal :never_run, state
        state = :ran_timed_out_op
      end

      add_op(type) do |run|
        assert_equal 0, run
        assert_equal :ran_timed_out_op, state
        state = :ran_both_ops
      end

      20.times do 
        async do 
          assert m = model_class(type).find(model(type).id)
          assert m.run_jobs
        end
      end
      join

      assert_equal :ran_both_ops, state
      assert_equal [], model(type).reload.pending_ops    
    end

    test "a completed #{type} op gets removed and execution proceeds" do
      state = :never_run

      add_op(type, :completed) { fail "Already completed, shouldn't get called" }

      add_op(type) do |run|
        assert_equal 0, run
        assert_equal :never_run, state
        state = :ran
      end

      assert model(type).reload.run_jobs
      assert_equal :ran, state
      assert_equal [], model(type).reload.pending_ops
    end
  end

  # Looks up the block at the specified index and calls it with the op index and run number if it exists
  def self.call_op_block(op, run)
    if @@op_blocks[op]
      case @@op_blocks[op].arity
      when 2
        @@op_blocks[op].call(op, run)
      when 1
        @@op_blocks[op].call(run)
      else
        @@op_blocks[op].call()
      end
    else
      fail "No op block found for #{op}"
    end
  end

  private
    # Mock methods for constants affecting run_jobs. Opts keys are
    # :retries (default 10)
    # :sleep (seconds, default .1)
    # :timeout (seconds, default 30)
    def set_timeouts(opts={})
      Domain.any_instance.expects(:run_jobs_max_retries).at_least(0).returns(opts[:retries] || 10)
      Domain.any_instance.expects(:run_jobs_retry_sleep).at_least(0).returns(opts[:sleep] || 0.1)
      Domain.any_instance.expects(:run_jobs_queued_timeout).at_least(0).returns(opts[:timeout] || 30)
      Team.any_instance.expects(:run_jobs_max_retries).at_least(0).returns(opts[:retries] || 10)
      Team.any_instance.expects(:run_jobs_retry_sleep).at_least(0).returns(opts[:sleep] || 0.1)
      Team.any_instance.expects(:run_jobs_queued_timeout).at_least(0).returns(opts[:timeout] || 30)
    end

    # Run the given block in a new thread
    def async(&block)
      @threads ||= []
      index = @threads.length
      @threads << Thread.start do
        yield block
      end
    end

    # Wait for all async blocks to complete, up to the limit in seconds
    def join(limit=30)
      t1 = Time.now.to_f
      begin
        @threads.map{ |t| limit ? t.join(limit - (Time.now.to_f - t1)) : t.join }
      ensure
        @threads.each(&:kill)
        @threads = nil
      end
    end

    # Add a mock op to the model of the given type
    def add_op(type, state=:init, queued_at=0, &block)
      case type
      when "team"
        op = MockTeamOp.new(:op => @@op_blocks.length, :state => state, :queued_at => queued_at)
      when "domain"
        op = MockDomainOp.new(:op => @@op_blocks.length, :state => state, :queued_at => queued_at)
      else
        raise "Unknown type #{type}"
      end
      model(type).pending_ops.push(op)
      @@op_blocks << block
      op
    end

    # Get the instance variable for the model of the correct type
    def model(type)
      case type
      when "team"
        @team
      when "domain"
        @domain
      else
        raise "Unknown type #{type}"
      end
    end

    # Get the model class of the correct type
    def model_class(type)
      case type
      when "team"
        Team
      when "domain"
        Domain
      else
        raise "Unknown type #{type}"
      end
    end

    # Mock a domain op to:
    # 1. keep track of how many times it has been run
    # 2. mark itself complete once the corresponding block runs without exception
    class MockDomainOp < PendingDomainOps
      field :op, type: Integer, default: 0
      field :run, type: Integer, default: 0

      def completed?
        self.state == :completed
      end

      def execute
        i = self.run || 0
        set :run, i+1
        PendingOpsTest.call_op_block(op, i)
        set_state :completed
      end
    end

    # Mock a team op to:
    # 1. keep track of how many times it has been run
    # 2. mark itself complete once the corresponding block runs without exception
    class MockTeamOp < PendingTeamOps
      field :op, type: Integer, default: 0
      field :run, type: Integer, default: 0

      def completed?
        self.state == :completed
      end

      def execute
        i = self.run || 0
        set :run, i+1
        PendingOpsTest.call_op_block(op, i)
        set_state :completed
      end
    end

end