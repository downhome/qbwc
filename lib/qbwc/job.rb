class QBWC::Job

  attr_reader :name, :company, :response_proc
  attr_accessor :next_request

  def initialize(name, company, *requests, &block)
    @name = name
    @enabled = true
    @company = company || QBWC.company_file_path
    @requests = requests
    @code_block = block
    @check_pending = lambda { self.next }

    self.reset
  end

  def set_checking_proc(&block) 
    @check_pending = block
  end

  def set_response_proc(&block) 
    @response_proc = block
  end

  def process_response(response, advance)
    @next_request += 1 if @requests.present? && advance
    @response_proc && @response_proc.call(response) 
  end

  def enable
    self.enabled = true
  end

  def disable
    self.enabled = false
  end

  def pending?
    enabled? && @check_pending.call
  end

  def self.enabled=(value)
    @enabled = value
  end

  def enabled?
    @enabled
  end

  def next
    request = @request_gen.call
    QBWC.storage_module::Request.new(request) if request
  end

  def reset
    if @requests.present?
      @request_gen = lambda { @requests[@next_request] }
    else
      @request_gen = @block
    end
  end

  private

  def request_queue
    QBWC::Request.from_array(@requests.call, @response_proc )
  end

end
