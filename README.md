# Dark Sun

This repo contains the developmental Dark Sun NWN1:EE module content.  If you want to contribute, please fork this repository and send a pull request when your testing is complete.

## HCR2

HCR2 is incorporated into this framework as a plugin (designated `pw`).  Just about all the code within this subdirectory is straight out of Edward Beck's HCR2 creation.  There's been some code removed to allow it work more readily in the library framework we're using.  Generally, however, it remains intact.

## Core Framework

The entire module rests on Michael Sinclair's (squattingmonk) [core framework](https://github.com/squattingmonk/nwn-core-framework).  The `framework` folder is a fork directly off his repository.  **There will be no pull requests accepted that involve changes to any script in this folder.**

## Plugins

### Dark Sun
The `ds` folder contains Dark Sun specific plugins that modify or otherwise hook into the base module systems (HCR2 and core framework)

### DMFI
DMFI development is currently underway and will not be included in the module when you install it.  The scripts do not yet compile and are under heavy revision.  If you modify nasher.cfg to include these scripts, you will not be able to install correctly run the module.  When development is complete, the scripts will automatically be included in the module.

### Working
The `working` folder is used to store scripts that are currently under revision.  This folder will not be included in a module installation, so don't put any scripts there.

## Server
The server will be setup with a docker version of nasher so we don't have to keep uploading .mod files to the server.  I'll let you know when that's complete and how to build the module on the VM server.

## Contributing
If you want to contribute, create a fork off this repository.  Any work you do will automatically be saved to the appropriate folder when you `nasher unpack` your saved work.  The only except to this is scripts.  New scripts will be saved to the `module` base folder so they're easy to find.