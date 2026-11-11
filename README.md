# Docker PHP devbox

 * PHP 8.5
 * neovim with PHP edition tools
 * xdebug.ini file
 * claude code

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

  # additional configuration for default folder, claude and opencode
  app.vm.provision :shell, privileged: false, env: app_vars,  :inline => <<-END
    echo 'cd /vagrant' >> /home/ubuntu/.zshrc
    echo "export PATH=/vagrant/bin:$PATH" >> /home/ubuntu/.zshrc
    echo "export PATH=/home/ubuntu/.local/bin:$PATH" >> /home/ubuntu/.zshrc
    echo "export PATH=/home/ubuntu/.opencode/bin:$PATH" >> /home/ubuntu/.zshrc
  end

  ...
```

## Use Opencode

```sh
opencode2 auth login opencode
opencode2
```
