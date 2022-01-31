# tfimport (WIP)
This is a tool that wraps commands to assist import.

# Solution

Now that DevOps has advanced, is there anything like this?
I've created the infrastructure, so please "terraform import" it.
It's a pain in the ass to get used to. Read the documentation from the official site every time.
This is Toil.
This tool was created with the hope that anyone can import it easily.

# Feature
- You can choose which resources to import interactively.
- Can save configuration information in batches

# Require

This tool needs to be able to execute the following commands.
You just need to place the shell script and definition files on a linux server and it will work.

- [AWS CLI](https://aws.amazon.com/jp/cli/)
- [terraform](https://www.terraform.io/downloads)
- [peco](https://github.com/peco/peco)
- jq
- standard unix environment

note) terraform and peco can be specified without a path.

# Usecase
## Interactive mode

If you run it without any arguments, you will be in the mode of selecting the resource you want to import from the menu.

```
./tfimport.sh
```

## Batch mode

When you specify a label and target resource, the selection screen does not appear, and it works in batch mode.

```
./tfimport.sh (target) (name)
```

# config file

```
TFIMPORTPATH
```

With this definition, terraform and peco will be used in the specified path
export TFIMPORTPATH+/usr/bin

- TFIMPORTPATH



# license
MIT License
