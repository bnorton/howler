# Howler
###An asynchronous message queue that's always chewing on something.
--------------------

#####Advantages
- Simple message queueing interface.
- Powerful and Fine-grained message retry logic.
- Dashboard for managing and tracking message processing.
- No need for an external Exception Notification Service.
- Simple Message passing between Actors

--------------------

###Usage
1. `gem 'howler'`.
2. `bundle install`.
3. From the root of the Rails project run `[bundle exec] howler`.

####Queueing Interface

```ruby
class User [< ActiveRecord::Base]
  async :fetch_content

  def self.fetch_content(user_id)
    ...
  end
end

User.async_fetch_content(user.id)
#=> true
```

####Message Retry Handling
- Retry a message every minute for up to 10 minutes

```ruby
  def self.fetch_content(user_id)
    user = User.find(user_id)

    unless user.fetchable?
      raise Howler::Message::Retry(:after => 1.minute, :ttl => 10.minutes)
    end

    ... # fetch content
  end
```

####Exception Notification
- Notify when an external API is down

```ruby
  def self.fetch_content(user_id)
    ...
    begin
      # Try to fetch /home_timeline for the user
    rescue Twitter::Error::ServiceUnavailable => error
      raise Howler::Message::Notify.new(erorr)
    end
    
    ... # process the timeline
  end
```

####Message Passing
- Pass messages by setting values into the shared configuration (key, value).

```ruby
  def fetch_content(user_id)

    ... # done fetching content
    Howler::Config[user_id] = {:fetched_at => Time.now, :status => 'success'}.to_json

    # Then to delete a key simply assign nil
    Howler::Config[user_id] = nil
  end
```

####Dashboard (In Development)
--------------------
- Global settings management.
- Change the default message retry handling.
- Increase or Decrease the number of workers.
- Explicitly retry, delete, or reschedule messages
- Change the log-level (seeing higher error rates, so switch to the debug level)

#####Get rid of your Exception Notifier
--------------------
- Simply raise a `Howler::Message::Notify` exception
- Raise with custom attributes and `Howler` will take care of the rest.
- The Notifications tab will give you access to errors in real-time.

