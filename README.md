# KONG: Microservice Management Layer

[![Build Status][travis-badge]][travis-url]
[![License Badge][license-badge]][license-url]
[![Gitter Badge][gitter-badge]][gitter-url]

- Website: [getkong.org][kong-url]
- Docs: [getkong.org/docs][kong-docs]
- Mailing List: [Google Groups][google-groups-url]

[![][kong-logo]][kong-url]

Kong was created to secure, manage and extend Microservices & APIs. Kong is powered by the battle-tested tech of NGINX and Cassandra with a focus on scalability, high performance & reliability. Kong runs in production at [Mashape][mashape-url] handling billions of requests to over ten thousand APIs.

## Core Features

- **CLI**: Control your Kong cluster from the command line just like Neo in The Matrix.
- **REST API**: Kong can be operated with its RESTful API for maximum flexibility.
- **Scalability**: Distributed by nature, Kong scales horizontally simply by adding nodes.
- **Performance**: Kong handles load with ease by scaling and using NGINX at the core.
- **Plugins**: Extendable architecture for adding functionality to Kong and APIs.
  - **Logging**: Log requests and responses to your system over TCP, UDP or to disk.
  - **Monitoring**: Live monitoring provides key load and performance server metrics.
  - **Authentication**: Manage consumer credentials query string and header tokens.
  - **Rate-limiting**: Block and throttle requests based on IP or authentication.
  - **Transformations**: Add, remove or manipulate HTTP params and headers on-the-fly.
  - **CORS**: Enable cross-origin requests to your APIs that would otherwise be blocked.
  - **Anything**: Need custom functionality? Extend Kong with your own Lua plugins!

## Architecture

If you're building for web, mobile or IoT (Internet of Things) you will likely end up needing common functionality on top of your actual software. Kong can help by acting as a gateway for HTTP requests while providing logging, authentication, rate-limiting and more through plugins.

[![][kong-benefits]][kong-url]

## Benchmarks

We set Kong up on AWS and load tested it to get some performance metrics. The setup consisted of three `m3.medium` EC2 instances; one for Kong, one for Cassandra and a third for an upstream API. After adding the upstream API's `target_url` into Kong we load tested from 1 to 2000 concurrent connections. Complete [reproduction instructions](https://gist.github.com/montanaflynn/01376991f0a3ad07059c) are available and we are currently working towards automating a suite of benchmarks to compare against subsequent releases.

Over two minutes **117,185** requests with an average latency of **10ms** at **976 requests a second** or about **84,373,200 requests a day** went through Kong and back with only a single timeout.

![](http://i.imgur.com/aDGRe4G.png)

## Development

1. Clone the repository and make it your working directory.
2. Run `[sudo] make install`

  This will build and install the `kong` luarock globally.

3. Run `make dev`

  This will install development dependencies and create your environment configuration files:

  - `kong_TESTS.yml`
  - `kong_DEVELOPMENT.yml`

4. Run the tests:

  ```bash
  make test-all
  ```

5. Run Kong with the development configuration file:

   ```bash
   $ kong start -c kong_DEVELOPMENT.yml
   ```

#### Makefile Operations

When developing, use the `Makefile` for doing the following operations:

| Name          | Description                                                              |
| -------------:| -------------------------------------------------------------------------|
| `install`     | Install the Kong luarock globally                                        |
| `dev`         | Setup your development environment                                       |
| `clean`       | Clean your development environment                                       |
| `start`       | Start the `DEVELOPMENT` environment (`kong_DEVELOPMENT.yml`)             |
| `seed`        | Seed the `DEVELOPMENT` environment (`kong_DEVELOPMENT.yml`)              |
| `drop`        | Drop the `DEVELOPMENT` environment (`kong_DEVELOPMENT.yml`)              |
| `lint`        | Lint Lua files in `kong/`                                                |
| `coverage`    | Run unit tests + coverage report                                         |
| `test`        | Run the unit tests                                                       |
| `test-all`    | Run all unit + integration tests at once                                 |

## Documentation

Complete & versioned documentation is available at [GetKong.org][kong-url]:

- [Latest Docs](http://www.getkong.org/docs/)
- [Installation](http://www.getkong.org/download)
- [Quick Start](http://getkong.org/docs/latest/getting-started/quickstart/)
- [Configuration](http://getkong.org/docs/latest/configuration/)
- [CLI Reference](http://getkong.org/docs/latest/cli/)
- [API Reference](http://getkong.org/docs/latest/admin-api)

[kong-url]: http://getkong.org/
[kong-docs]: http://getkong.org/docs/

[kong-contrib]: https://github.com/Mashape/kong/blob/master/CONTRIBUTING.md
[kong-changelog]: https://github.com/Mashape/kong/blob/master/CHANGELOG.md

[kong-logo]: http://i.imgur.com/4jyQQAZ.png
[kong-benefits]: http://i.imgur.com/2hg4orF.png

[mashape-url]: https://www.mashape.com

[travis-url]: https://travis-ci.org/Mashape/kong
[travis-badge]: https://img.shields.io/travis/Mashape/kong.svg?style=flat

[license-url]: https://github.com/Mashape/kong/blob/master/LICENSE
[license-badge]: https://img.shields.io/github/license/mashape/kong.svg

[gitter-url]: https://gitter.im/Mashape/kong
[gitter-badge]: https://img.shields.io/badge/Gitter-Join%20Chat-blue.svg

[google-groups-url]: https://groups.google.com/forum/#!forum/konglayer
