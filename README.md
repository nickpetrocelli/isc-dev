# ISC-DEV-IO
Export/Import sources in UDL format for [ISC Caché 2016.2](http://www.intersystems.com/our-products/cache/cache-overview/)

# Installation
Download code and run
```
set dir="/dir/cache-udl
do $System.OBJ.ImportDir(dir,"*.xml;*.cls;*.mac;*.int;*.inc;*.dfi","ck",,1)
```
or
import the [release](https://github.com/intersystems-ru/cache-udl/releases) to the namespace.

Map sc package to %All namespace to make it visible in any namespace.

# Usage

## Setup working directory ( optional )
```
NS> w ##class(sc.code).workdir("/path/to/your/working/directory/")
```
## Export to working directory:
```
NS> d ##class(sc.code).export()
```
## Import:
```
NS> d ##class(sc.code).import()
```

## Compile, Release and Patch:

Introduce isc.json file in the source root directory with settings for the code mask, for the name of the project and for get the patch form local git or GitHub. e.g.
```
"git": 0 - files diff from local git
"git": 1 - files diff from GitHub
```

```
isc.json
 "compileList": "Classes*.INC,classes*.CLS,*.DFI",
 "projectName": "myproject",
 "git": 0,
 "owner": "owner",
 "repository": "repository",
 "user": "user",
 "password": "password"
```
Run init method to initialize project settings:
```
NS> d ##class(sc.code).init()
```
Then run release to export all the classes in comileList into one "myproject.xml" release file. It will export it into the default for current Namespace directory.
```
NS> d ##class(sc.code).release()
```
Or compile it whenever you want to compile all the proejct related resources.
```
NS> d ##class(sc.code).compile()
```
Get last changes from github or local git. Run patch to export the classes in comileList into one "patch.xml" patch file. It will export it into the default for current Namespace directory or you can choose where export. By default, makes a patch from the last commit if you do not specify `commitFrom` and `commitTo` e.g.
```
NS> s filename = "c:\patch.xml"
NS> s commitFrom = 1
NS> s commitTo = 5
NS> d ##class(sc.code).patch(filename,commitFrom,commitTo)
```






