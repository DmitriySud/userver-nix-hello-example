# hello-service

A minimal [userver](https://userver.tech) HTTP service, based on userver's
`hello_service` sample. It responds on `/hello`:

- `Hello, unknown user!` for a request with no `name`
- `Hello, <name>!` for `/hello?name=<name>`

It depends on the `userver-nix` flake wrapper and builds with the **clang
stdenv**. Only the `userver::core` feature is used.

## Layout

```
flake.nix                  # clang-stdenv build + userver-nix dependency
CMakeLists.txt             # find_package(userver COMPONENTS core)
main.cpp                   # DaemonMain + MinimalServerComponentList
src/say_hello.{hpp,cpp}    # application logic
src/hello_handler.{hpp,cpp}# HTTP handler component
configs/static_config.yaml # startup config (port 8080, /hello route)
```

## Build & run (Nix)

Point the `userver-nix` input at your wrapper (edit `flake.nix`), then:

```sh
nix build            # builds the service
nix run              # runs it with the bundled static_config.yaml
```

Send a request from another terminal:

```sh
curl 127.0.0.1:8080/hello
# Hello, unknown user!

curl '127.0.0.1:8080/hello?name=userver'
# Hello, userver!
```

## Dev shell

```sh
nix develop
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/hello_service -c configs/static_config.yaml
```

`userver_DIR` is exported in the shell so `find_package(userver ...)` resolves
to the wrapper-built install. `clangd` and `clang-format` are available via
`clang-tools`.

## Notes

- The service links `userver::core` only; no DB/driver features are enabled in
  the wrapper for this build (`mkUserver { features = { core = true; }; }`).
- `src/hello_handler.hpp` and `main.cpp` include
  `userver/utest/using_namespace_userver.hpp`, which pulls the `userver`
  namespace into scope — this matches the upstream sample and is intended for
  samples/snippets. In a production service you'd typically qualify names
  explicitly instead.
- To change the listen port or route, edit `configs/static_config.yaml`.
