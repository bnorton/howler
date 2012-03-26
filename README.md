# SYM
###An Asynchronous Message Processing Library for Ruby

#####Sym uses actors to processes messages.
- By taking advantage of actors as the processing primitive, thread safety is built-in
- Actors are similar to a message queue out of the box so understanding the system is straightforward.

###The Web Client
######Provides deep introspection into the state of the queues.

####Aggregate:
- Current throughput
- Success/Error rates
- Set global configuration (retry count, log level)

####Per Queue
- View Pending, Current and Processed messages
- Success/Error rates
- Average time-to-completion
- A list of recent exceptions and back traces

####Per Message
- Introspect the message (class, method, arguments, created at)
- System and Observed Runtime
- Run, Retry or Delete the message

```ruby
class Worker
  async :fetch_content, :new_user_email

  def fetch_content
    ...
  end

  def self.new_user_email(user)
    ...
  end
end

...

# Then make calls to 'async_' prefixed class methods

Worker.async_fetch_content
#=> true # Returns immediately

Worker.async_new_user_email(user)
