/// Export different types of modules in different subfolders in UDL (plain) format
/// test.dfi -> /dfi/test.dfi
/// testpkg.test.cls -> /testpkg/test.cls
Class dev.code [ Abstract ]
{

Parameter version = "1.4.20";

/// export all available code
ClassMethod export(mask = "", generated = 0, system = 0, percent = 0, mapped = 0, dfi = 0)
{
	#define export(%code, %file) set sc = $system.OBJ.ExportUDL(%code, %file,"/diffexport") ##continue
								 write:sc "Ok" do:'sc $system.OBJ.DisplayError(sc)

	#define isGenerated(%code) ##class(%RoutineMgr).IsGenerated( %code )
	#define isPercented(%code) ("%" = $e(%code))
	#define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
	#define log write !, code, " -> ", $piece(filename,..workdir(),2), " "
						
	write "#; Exporting to ", ..workdir(),!
	#; classes
	set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:Summary")
	if rs.Execute() 
	{
		while rs.%Next()
		{
			set code = rs.Name _ ".cls", isSystem = rs.System
			if ( 'system && isSystem ) continue
			if ( 'generated && $$$isGenerated( code ) ) continue
			if ( 'percent && $$$isPercented( code ) ) continue
			if ( 'mapped && $$$isMapped( code ) ) continue
			if ( '..checkMasks( code, mask ) ) continue
			
			set filename = ..filename( code )
			do ..mkdir( filename )
			$$$log
			$$$export( code, filename )
		} 
		set rs=""
	}

	#; routines
	set rs = ##class(%ResultSet).%New("%Routine:RoutineList")
	if rs.Execute() 
	{
		while rs.%Next() 
		{
	 		set code = rs.Name
	 		write code,!
	 		if ( 'generated && $$$isGenerated( code ) ) continue
	 		if ( 'percent && $$$isPercented( code ) ) continue
			if ( 'mapped && $$$isMapped( code ) ) continue
			if ( '..checkMasks( code, mask ) ) continue
			
			set filename = ..filename( code )
			do ..mkdir( filename )
			$$$log
			$$$export( code, filename )

		} 
		set rs=""
	}

	#; dfi
	do ..fixDashIntoName()
	#define export(%code,%file) set sc = ##class(%DeepSee.UserLibrary.Utils).%Export( %code, %file, 0 ) 
	
	set sql = "Select id, fullName as Name, documentName From %DeepSee_UserLibrary.FolderItem"
    set rs = ##class(%SQL.Statement).%ExecDirect( .stm, sql )
	while rs.%Next() 
	{
		set code = rs.Name
		set filename = ..filename( code_".dfi" )
		set documentName = rs.documentName
		
		if ($L(code,"$TRASH")>1) continue
		
		if ( 'generated && $$$isGenerated( code ) ) continue
	 	if ( 'percent && $$$isPercented( code ) ) continue
		if ( 'mapped && $$$isMapped( code ) ) continue
		if ( '..checkMasks(documentName, mask) ) continue
		
		do ..mkdir( filename )
		
		if dfi
		{
			$$$log
			$$$export( code, filename)
		}
		elseif ('dfi)
		{
			set documentName = $replace(documentName,"/","-")
			set filename = $extract(filename,1,*-4)
			do ..fixXMLLine(documentName,filename_".xml")
		}

	} 
	set rs=""
	
	#;DeepSee artefacts
	do ..exportCubes()
	do ##class(dev.bi).exportDeepSeeArtefacts()
	write !,!, "#; Exported to ", ..workdir()
	
    return $$$OK
}

/// Method to export all cubes, source cube classes, dashboards, 
/// pivots and globals from the namespace available to the current user
/// do ##class(dev.code).exportBI()
ClassMethod exportBI() As %Status
{
	do ##class(dev.bi).exportCubes()
	do ##class(dev.bi).exportKPIs()
	do ##class(dev.bi).exportDashboards()
	do ##class(dev.bi).exportPivots()
	do ##class(dev.bi).exportDeepSeeArtefacts()
	
	return $$$OK
}

/// Export Cube Classes
ClassMethod exportCubes() As %Status
{
	#define export(%code, %file) set sc = $system.OBJ.ExportUDL(%code, %file,"/diffexport") ##continue
								 write:sc "Ok" do:'sc $system.OBJ.DisplayError(sc)
	#define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
	#define isPercented(%code) ("%" = $e(%code))
	#define isCube(%code) $classmethod(%code,"%Extends","%DeepSee.CubeDefinition")
	
	#define log write !, code, " -> ", $piece(filename,..workdir(),2), " "
	
	Set sc = $$$OK
	#; classes
	set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:Summary")
	if rs.Execute() 
	{
		while rs.%Next()
		{
			set code = rs.Name _ ".cls", isSystem = rs.System
			if isSystem continue
			if $$$isPercented( code ) continue
			if $$$isMapped( code )  continue
			
			if '($classmethod(rs.Name,"%Extends","%DeepSee.CubeDefinition")) continue
			set filename = ..filename( code )
			do ..mkdir( filename )
			$$$log
			$$$export( code, filename )
		} 
		set rs=""
	}


	Return sc
}

/// import all from workdir
ClassMethod import(filemask = "*.xml;*.cls;*.mac;*.int;*.inc;*.dfi", qspec = "cku-d", ByRef err = "", recurse = 1, ByRef loaded = "", verbose = 1) As %Status
{
	#define push(%dir) set dirs( $i( dirs ) ) = %dir
	#define next(%i,%dir) set %i=$o( dirs( "" ), 1, %dir )  kill:%i'="" dirs(%i)
	#define isDirectory(%type) ( %type = "D" )
	#define log write !, $piece(filename,..workdir(),2), " " write:sc "Ok" do:'sc $system.OBJ.DisplayError(sc)
	
	set sc = 1, dirs = "", dir = ..workdir() $$$push(dir)
	if verbose write "#; Importing from ", dir,!
	do ..setIgnore(.fm,verbose)
	for 
	{ 
		$$$next(i,dir) quit:i=""  quit:dir=""
		set rs = ##class(%File).FileSetFunc( dir, filemask, , 1 )

		while rs.%Next() 
		{
			set filename = rs.Name

			if $$$isDirectory(rs.Type) {
				if recurse $$$push(filename)
				continue
			}
			// check file filter
			if ..inFilter(.fm,filename) continue

			set ext = $zcvt($p( filename, ".", * ),"l")

			if (ext = "dfi") {
				set sc = ##class(%DeepSee.UserLibrary.Utils).%Import( filename, 1, 0, 0, "", .dsloaded )

			} else {
				// load classes only
				set sc = $system.OBJ.Load( filename, "k-d", .err, .loaded)
			}

			if verbose $$$log
			
	    }
		// compile all the loaded classes to obey dependencies
		set sc=$system.OBJ.CompileList( .loaded, "cukbr-d/multicompile",.err )
		
	}
	
	if verbose {
	
		if $D(err) {
			set i=$Order(err("")) 
			while i'="" {
			write !,err(i)
			set i=$O(err(i))
			}
		}
		
		write !,!,"#; Imported from ", ..workdir()
		}
	return sc
}

ClassMethod exportGlobals(mask = "") As %Status
{
	#include %occInclude
	set statement=##class(%SQL.Statement).%New()
 	set sc=statement.%PrepareClassQuery("%SYS.GlobalQuery","NameSpaceListChui")
 	if $$$ISERR(sc) { do $system.OBJ.DisplayError(sc) }
 	set resultset=statement.%Execute($namespace)
	while resultset.%Next() 
	{
   	 	set gname = resultset.%Get("Name")
   	 	
   	 	continue:$data(@("^"_gname))=0
   	 	continue:$$$isGenerated(gname)
	 	continue:$$$isPercented(gname)
		continue:$$$isMapped(gname)
		continue:'..checkMasks(gname, mask)
		
		set gname = gname_".GBL"
		set filename = ..filename(gname)
		do ..mkdir(gname)

		set sc = ..fixXMLLine(gname, filename_".xml")
 	}
 	return sc
}

ClassMethod patch(filename = "", commitFrom = "", commitTo = "") As %Status
{
	set gln = ..gln()
	set git = @gln@("git")

	set:commitTo="" commitTo=1
	if (git = 0) 
	{
		set:(commitFrom="")||(commitFrom=1) commitFrom=0
		set sc = ##class(dev.diff.gitLocal).buildDiff(..workdir(), "HEAD~"_commitTo, "HEAD~"_commitFrom, .items)
		return:$$$ISERR(sc) sc
	}
	elseif(git = 1) 
	{
		set owner = @gln@("owner")
		set repository = @gln@("repository")
		set user = @gln@("user")
		set password = @gln@("password")
		set:commitFrom="" commitFrom=1
		
		set sc = ##class(dev.diff.gitHub).Get(.items, owner, repository, user, password, commitFrom, commitTo)
		return:$$$ISERR(sc) sc	
	}
	
	if (filename="") 
	{
		set filename=$G(@gln@("projectName"),"patch")
		set filename=filename_$p($zdt($h,8)," ")_$tr($p($p($zdt($h)," ",2),":",1,2),":")_".xml"	
	}
	zw filename
	set sc = $system.OBJ.Export(.items,filename)
	
	return sc
}

ClassMethod fixXMLLine(documentName, filename) As %Status
{
	set stream = ##class(%Stream.FileBinary).%New()
	do stream.LinkToFile(filename)
	do $system.OBJ.ExportToStream(documentName, .stream)

	set matcher=##class(%Regex.Matcher).%New("<Export generator=.+>")
	set matcher.Text = stream.Read(stream.Size)
	set data = matcher.ReplaceFirst("<Export generator=""Cache"">")
	
	do stream.Clear()
	do stream.Write(data)
	return stream.%Save()
}

ClassMethod inFilter(ByRef filtermask, filename) As %Boolean
{
	set result=0
	for 
	{
		if '$d(filtermask($I(i))) quit
		set filter=$piece(filtermask(i),"*")
		if $length(filename,filter)>1 set result=1
	}

	return result
}

/// get the filtermask for the repository.
/// looks for .gitignore file and applies all the lines to filters
ClassMethod setIgnore(ByRef filtermask, verbose)
{
	// working with .gitignore file
	// gitignore consists of masks of filtering files
	set filename=..workdir()_"/.gitignore"
	if '##class(%File).Exists(filename) quit
	set file=##class(%File).%New(filename)
	set sc=file.Open("R")
	if 'sc 
	{
		if verbose do $System.OBJ.DisplayError(sc) return
	}

	While 'file.AtEnd
	{
		set filtermask($I(filtermask))=file.ReadLine()
	}
	quit
}

/// get or set working directory for export/import source
ClassMethod workdir(workdir)
{
	set:$d(workdir) workdir = ##class(%File).NormalizeDirectory(workdir)
	set gln = ..gln() 
	set:$d(workdir) @gln = workdir
	
	///zu(12) namespace directory by default
	#define nsdir $zu(12,"")
	return $g(@gln, $$$nsdir)
}

/// gl[obal] n[ame] - storage for settings
ClassMethod gln() [ CodeMode = expression, Private ]
{
"^"_$classname()
}

ClassMethod init(confile = "isc.json")
{
	quit:..workdir()="" "workdir is empty"
	quit:'##class(%File).Exists(..workdir()_confile) "configuration file: "_confile_" not found in "_..workdir()
	
	set stream=##class(%Stream.FileCharacter).%New()
	set sc=stream.LinkToFile(..workdir()_confile)
	set conf={}.%FromJSON(stream.Read($$$MaxCacheInt))
	
	set gln = "^dev.code"
	
	set @gln@("compileList")=conf.compileList
	set @gln@("projectName")=conf.projectName
	set @gln@("owner")=conf.owner
	set @gln@("repository")=conf.repository
	set @gln@("user")=conf.user
	set @gln@("password")=conf.password
	set @gln@("git")=conf.git
	set:@gln@("git")="" @gln@("git")=0
	
	write "compileList="_conf.compileList,!
	write "projectName="_conf.projectName,!
	write "owner="_conf.owner,!
	write "repository="_conf.repository,!
	write "user="_conf.user,!
	write "password="_conf.password,!
	write "git="_conf.git,!
	
	quit $$$OK
}

/// export release file for list and project settings
ClassMethod release()
{
	set gln=..gln()
	set list=$G(@gln@("compileList"))
	if list="" write "Nothing to release. Run init method first" quit

	set release=$G(@gln@("projectName"),"release")
	set release=release_$p($zdt($h,8)," ")_$tr($p($p($zdt($h)," ",2),":",1,2),":")_".xml"
	do $System.OBJ.Export(list,release)
	write "All objects with mask "_list_" has been exported to "_release
}

ClassMethod compile()
{
	set gln=..gln()
	set list=$G(@gln@("compileList"))
	if list="" write "Nothing to compile. Run init method first" quit
	do $System.OBJ.compile(list)
}

/// test.dfi -> /dfi/test.dfi
/// test.cls -> /cls/test.cls
/// testpkg.test.cls -> /cls/testpkg/test.cls
/// etc
/// w ##class(dev.code).filename()
ClassMethod filename(code)
{
	#define log(%dir,%sc) w !, "mkdir ", %dir, " ", sc

	set wd = ..workdir()

	if '##class(%File).DirectoryExists( wd ) {
		set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	set ext = $p( code, ".", * ), ext = $zcvt( ext, "l" )

	// for each type - different directory
	set extensions = $lb("int","inc","mac","dfi","gbl")
	if ($lf(extensions, ext)>0)
	{
		set wd = ##class(%File).NormalizeDirectory( ext, wd )
	}

	// directory must exist before any call (%File).NormalizeFilename( , wd)
	if '##class(%File).DirectoryExists( wd ) 
	{
		set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	set filename = ##class(%File).NormalizeFilename( code, wd )
	
	// lowercase file extension
	set $p(filename,".",*)=ext
	
	#; for *.cls Package.Subpackage.ClassName.cls -> Folder/Subfolder/ClassName.cls
	if (ext="cls")
	{
		set dirs = $piece( code, ".",1, *-2 ), dirs = $translate( dirs, ".", "/" )
		set relpath = dirs _ "/" _ $piece( code, ".", *-1, * ) ;
		set filename = ##class(%File).NormalizeFilename( relpath, wd )
	}

	return filename
}

/// import from workdir all files with ts newer than code ts in db
ClassMethod importUpdated(filemask = "*.*", qspec = "cku-d", ByRef err = "", recurse = 1, ByRef loaded = "", verbose = 1) As %Status
{
	#define push(%dir) s dirs( $i( dirs ) ) = %dir
	#define next(%i,%dir) s %i=$o( dirs( "" ), 1, %dir )  k:%i'="" dirs(%i)
	#define isDirectory(%type) ( %type = "D" )
	#define log w !, $piece(filename,..workdir(),2)," " w:sc "Ok" d:'sc $system.OBJ.DisplayError( sc )

	set sc = 1, dirs = "", dir = ..workdir() $$$push(dir)
	if verbose write "#; Importing updated from ", dir,!
	do ..setIgnore(.fm,verbose)
	for 
	{ 
		$$$next(i,dir) quit:i=""  quit:dir=""

		set rs = ##class(%File).FileSetFunc( dir, filemask, , 1 )

		while rs.%Next() 
		{
			set filename = rs.Name

			if $$$isDirectory( rs.Type ) 
			{
				if ( recurse ) $$$push(filename) ;push directory
				continue
			}

			// check file filter
			if ..inFilter(.fm,filename) continue

			set filets = rs.DateModified
			set codename = ..codename( filename, .ext )
			set codets = ..codets( codename, ext )
			
			if ( filets '] codets ) continue
				
			if (ext = "dfi"){
				set sc = ##class(%DeepSee.UserLibrary.Utils).%Import( filename, 1, 0, 0, "", .dsloaded )
			} else 
			{
				#; drop existing code before import ( purge DateModified )
				#; s:codets'="" sc = ##class(%RoutineMgr).Delete( codename )
				kill err 
				set sc = $system.OBJ.Load( filename, qspec, .err, .loaded)
			}
			if verbose $$$log
	    }
	}
	write:verbose !,"#; Imported updated from ", ..workdir()
	return sc
}

/// presumable codename
ClassMethod codename(filename, ByRef ext = "")
{
	set ext = $p( filename, ".", * ), ext = $zcvt( ext, "l" )
	set path = ##class(%File).NormalizeDirectory( ext, ..workdir() )
	set codename = $p( filename, path, 2 )
	if ext = "dfi" {
		set fullname  = $tr( codename, "\", "/" ) ; return fullname for dfi in $$$IsWINDOWS
		quit $p( fullname, ".", 1, *-1 ) ;remove extension
	}
	if (ext ="cls")!(ext="int")!(ext="inc")!(ext="mac") s codename=$tr(codename,"\/","..")
	quit codename
}

ClassMethod codets(codename, ext)
{
	set ts = ""
	if ext'="dfi" {
		set ts = ##class(%RoutineMgr).TS( codename )
	} else 
	{
		set sql="Select timeModified From %DeepSee_UserLibrary.FolderItem Where fullname = ?"
		set rs = ##class(%SQL.Statement).%ExecDirect( , sql, codename )
		if rs.%Next() 
		{
			set utcts = rs.timeModified
			set utch = $zdth( utcts, 3, , 3 ) ;utc internal format
			set loch = $zdth( utch, -3 ) ; utc to local timezone
			set ts = $zdt( loch, 3, ,0 ) ; local timestamp*/
		}
	}
	return $p( ts, "." ) ;remove ms
}

// fix "-" into dfi files

ClassMethod fixDashIntoName()
{
	set sql = "Select id, fullName as Name, documentName From %DeepSee_UserLibrary.FolderItem"
    set rs = ##class(%SQL.Statement).%ExecDirect( .stm, sql )
    while rs.%Next() {
		if $find(rs.Name, "-"){
			write rs.Name," -> "
			set item = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(rs.id)
			set item.name = $replace(item.name,"-"," ")
			write item.name,!
			do item.%Save()
		}
    }
    kill rs
}

ClassMethod mkdir(filename As %String) As %Status
{
	set sc = $$$OK
	set path = ##class(%File).GetDirectory(filename) 
	if '##class(%File).DirectoryExists(path) 
	{
		set sc = ##class(%File).CreateDirectoryChain(path) 
		write !, "mkdir ", path, " ", sc 
	}
	return sc
}

ClassMethod getVersion() [ CodeMode = expression ]
{
"Version: "_..#version
}

ClassMethod checkMasks(name As %String, masks As %String) As %Boolean
{
	return:masks="" 1
	return:name="" 0
	
	set name = $zcvt(name,"l")
	set masks =  $zcvt(masks,"l")
	
	for i=1:1:$l(masks,",")
	{
		set pattern = "^"
		set mask = $p(masks, ",", i)
		
		for index=1:1:$l(mask)
		{
			set char = $e(mask, index)
    		set pattern = pattern _ $case(char,
    									  ".":"\.",
    									  "?":".",
    									  "*":".*",
    									     :char
    									  )	
		}
		set pattern = pattern _ "$|"
	}
	set pattern = $e(pattern,1,*-1)
	set matcher=##class(%Regex.Matcher).%New(pattern, name)
	do matcher.Locate() 
	return $select(matcher.Group="":0, 1:1)
}

}
