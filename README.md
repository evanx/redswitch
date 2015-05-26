
## Redix Router

Node and Redis-based message router and stream processing framework to route messages between Redix processors, and Redis queues e.g. for reactive microservices.

Redix is essentially a configurable logic layer for messaging between collaborating microservices.


## Overview

Messages are imported from external sources (including Redis queues and other Redix instances) and similarly exported. Otherwise they are routed between internal Redix processors.

Metadata is attached to messages e.g. for routing and processing purposes.

The first use-case we wish to fulfil is a reliable queue for multiple consumers, implemented as follows:
- pop incoming messages from a Redis producer queue
- push each incoming message onto multiple consumer queues
- microservices consume messages, and might reply later, or feedback error information.

The above enables reliable messaging for multiple reactive consumers. If a consumer is busy, or crashed, its messages are delivered when it is available again, via its dedicated persistent Redis queue.

Also note that multiple workers can operate off a single consumer queue for scalability and resilience.

## Processors

A "processor" is a component that processes messages.

Processors might be classified as follows:
- importer - import a message from a external source.
- exporter - export a message to an external source.
- router - dispatch a message (internally).
- enqueuer - dispatch a message into a Redis queue.
- dequeuer - pop a message from a Redis queue, and dispatch this message.
- compacter - eliminate messages from a queue.

We will implement a number of generally useful built-in processors, and accept contributions.

We enable custom and third-party processors as "plugins."

Messaging passing between processors is preferrably via Redix message queues to improve resilence and management.

Metrics should be published by processors, for performance monitoring and management.


## Configuration

Currently each processor is configured via a YAML file in the Redix `config` directory. This should be managed using a private git repository, which then provides versioning.

The a naming convention for each processor (and its configuration file) has a colon-delimited notation e.g. `builtin:FileImporter:default.`

This name is comprised of its Node module, JavaScript class, and finally its distinguishing instance name.

The "module" name enables custom and third-party processors e.g. a `myredix:FancyProcessor` where `myredix` is an `npm` module which exports a `FancyProcessor` class.

The distinguishing name enables multiple instances of the same processor class, configured for different purposes.

Note that `npm` enables version dependency via `package.json.` Also, multiple versions of the same module can be installed as differently named modules, e.g. `myredix-2.0.0:FancyProcessor.`


## Messages

The following design is recommended for messages.

The interface for each message types can be defined, and should be versioned. We define the mandatory and optional properties, their types e.g. string, int, boolean, and their contracts. This is useful for assertions during testing, and automated error handling.

Otherwise transformative processors can be used to coerce messages into the expected format or required version.

However, we expect multiple versions of processors will be installed e.g. to support older messages for some period.


## Concurrency

We use message queues to avoid concurrent operations.

Both Redis and Node have single-threaded event loops, which simplifies concurrency.

We use Redis for message queues and "shared memory" accessed by Redix processors, and our microservices.

Our processors are message-passing "actors," and otherwise must use Redis transactions.


## Examples

### FileImporter

Import a message from a directory.

Config: `FileImporter.default.yaml`
```yaml
watchDir: tmp/fileImporter/import/
replyDir: tmp/fileImporter/export/
route:
- HttpClient.default
```

Incoming message: `fileImporter/import/1.yaml`
```yaml
method: GET
url: http://data.iol.io/s/frontage
```

Reply: `fileImporter/export/1.json`
```json
{
  "id": 1862764,
  "link": "http://www.iol.co.za/sport/soccer/platini-won-t-vote-for-blatter",
  "published": "2015-05-25T09:03:19.000Z",
  "title": "Platini won’t vote for Blatter",
}
```

### HttpClient exporter

Export a message via an HTTP request.

Config: `HttpClient.default.yaml`
```yaml
message:
- method # e.g. GET, POST
- url
```

Incoming message: `tmp/fileImporter/import/1.yaml`
```yaml
method: GET
url: http://data.iol.io/s/frontage
```

### RedisHttpRequestImporter

Import an HTTP request message from an "external" Redis queue.

Config: `RedisHttpRequestImporter.default.yaml`
```yaml
queue: test:http # the redis key for the queue (list)
message:
- method # e.g. GET, POST
- url
```
