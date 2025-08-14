# Docker PHP devbox

 * PHP 8.4
 * neovim with PHP edition tools
 * xdebug.ini file

## Build the container

```sh
docker build -t jean553/docker-devbox-php .
```

## Vagrant usage

```ruby
...

config.vm.define "dev", primary: true do |app|

  app.vm.provider "docker" do |d|
    d.force_host_vm = false
    d.image = "jean553/docker-devbox-php"
    d.name = "#{PROJECT}_dev"
    d.has_ssh = true
  end

  ...
```
