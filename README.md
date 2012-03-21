# SYM
###An Asynchronous Message Processing Library for Ruby

#####Sym uses actors to processes messages.
- By taking advantage of actors as the processing primitive, thread safety is built-in
- Actors act similar to a message queue out of the box so understanding the system is straightforward.

#####A shared queueing model ensures that messages are processed on time.
- Add messages to a shared queue to make sure that no single message is processed more frequent than every x seconds (ensure a rate limit is not exceeded.
- Messages can have queue-level priority

###The Web Client
######Provides deep introspection into the state of the queues.

####Aggregate:
- Current throughput
- Success/Error rates
- Set global configuration (retry count, log information level)
- Set queue priority

####Per Queue
- Current Message being processed
- Success/Error rates
- Average time-to-completion
- Set the retry interval.
- Retry or Delete failed jobs
- A list of recent exceptions and back traces
