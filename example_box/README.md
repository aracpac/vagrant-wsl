# Vagrant WSL Example Box

Vagrant providers each require a custom provider-specific box format.
This folder shows the example contents of a box for the `wsl` provider.
To turn this into a box:

```
$ tar cvzf wsl.box ./metadata.json ./install.tar.gz
```

This box works by registering the install.tar.gz archive with WSL.
