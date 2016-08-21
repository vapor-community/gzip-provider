# gzip-vapor

[![Build Status](https://travis-ci.org/czechboy0/gzip-vapor.svg?branch=master)](https://travis-ci.org/czechboy0/gzip-vapor)
![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OS%20X-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-SwiftPM-yellow.svg)

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

> gzip support for Vapor

# Usage

When setting up your Vapor Droplet, just add this line for the server to automatically send responses gzipped (if the client declares support for it).

```swift
drop.middleware.append(GzipServerMiddleware())
```

(Also contains a `GzipClientMiddleware` for when Vapor support `Client` middlewares.)

# Installation

## Swift Package Manager

```swift
.Package(url: "https://github.com/czechboy0/gzip-vapor.git", majorVersion: 0, minor: 1)
```

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)

