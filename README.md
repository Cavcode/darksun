# Dark Sun

This repo contains the developmental Dark Sun NWN1:EE module content.  If you want to contribute, please fork this repository and send a pull request when your testing is complete.

# Tutorials

This section is provided for team members, or any potential contributors, in case they are not familiar with the tools we are using or what an effective work flow looks like.  If you're a seasoned developer or contributor, feel free to continue using your own processes.  You don't need permission to fork the repository and ask to contibute something.  If you don't know how to fork the repository, [check out our installation tools tutorial](docs/tools.md/#github-account).

## Development Tools

[Read the Tool Installation Tutorial](docs/tools.md)

For anyone that doesn't already have a development environment set on their machines, the [tool installation tutorial](docs/tools.md) will walk you through setting up the minimum tools you should have to enable an efficent development workflow.  You can develop without these tools, however, you will likely find that using them will save you countless hours of unnecessary work over the course of this module's development.  Also, any work you create that you cannot add to the repository yourself is creating unnecessary work for another member of the team.  So, live them, learn them, love them.  They really do save time.

## Workflow

[Read the Workflow Tutorial](docs/workflow.md)

The whole purpose of setting up these tools is to create an efficient development environment.  To that end, the workflow tutorial will walk you through using the various tools you installed in the tool installation tutorial and provide the foundation for quickly creating and deploying new content.

## Using VSCode as a Development Environment

[Coming soon! ~~Read the VSCode Installation and Setup Tutorial~~](docs/vscode.md)

For the scripters among us, and even those who are more daring, I highly suggest using Visual Studio Code as your prefered development environment.  It is lightweight, agile, contains a powershell terminal, interaces with your git repository and allow you to stage and commit changes to your forked repository.  Additonally, you edit, debug and compile all of you scripts directly in the program without ever having to touch the toolset.

## Letting the team know about issues with the module

[Coming soon! ~~Read the Issues tutorial~~](docs/issues.md)

This is for team members and players.  For players, you can submit bugs you find in-game.  For team members, you can request help with issues and attach those request to specific files in a pull request.  If you're not familiar with the Issues functionality on GitHub, [this tutorial](docs/issues.md) is for you.

## Adding to our Wiki

[Coming soon! ~~Read the Wiki tutorial~~](docs/wiki.md)

The wiki pages on this site should contain documentation on the major system of the module, as well as story background and other information.  If you want to contribute to our wiki, but don't know how, [this tutorial](docs/wiki.md) is for you.

# Module Systems

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