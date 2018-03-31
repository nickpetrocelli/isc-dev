# ISC-DEV
Export/Import source code (classes, macro, routines) and DeepSee artefacts(pivots, dashboards, termlists, pivot variables, shared measures) from and to InterSystems Data Platform products(Caché, Ensemble, IRIS). Support versions from 2016.2

# Installation
Download code and run
```
set dir="/your_download_dir/isc-dev
do $System.OBJ.ImportDir(dir,"*.xml;*.cls;*.mac;*.int;*.inc;*.dfi","cuk",,1)
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
"git": 0 - files diff from local git (default)
"git": 1 - files diff from GitHub
use below params in case of "git" : 1
"owner":  - name of the github e.g. intersystems-community
"repository": - name of the repo e.g. dc-analytics
 "user": - user and password for private github repo
 "password": 
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

## Known issues
Be careful with import termlists, pivot variables and shared measures. In current implementation imported artefacts replace those you have in the target namespace. It happens because the utility uses standard global import for globals in XML with $System.OBJ.Import which kills the global first and imports the new one.






