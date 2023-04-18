Class dev.bi
{

/// do ##class(dev.bi).exportCubes()
ClassMethod exportCubes() As %Status
{
				 					 
	set sc = ##class(%DeepSee.Utils).%GetCubeList(.listOfCubes,"cubes")
	
	set key = $order(listOfCubes(""))
	
	while (key'="")
	{
		set cubeClassName = ##class(%DeepSee.Utils).%GetCubeClass(key)
		set cubeSourceClassName = ..getSourceClass(key)
		
		do ..exportUDL(cubeClassName_".cls")
		do ..exportUDL(cubeSourceClassName_".cls")
		
		set key = $order(listOfCubes(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).exportKPIs()
ClassMethod exportKPIs() As %Status
{
	
	set sc = ##class(%DeepSee.Utils).%GetKPIList(.listOfKPIs)
	
	set key = $order(listOfKPIs(""))
	
	while (key'="")
	{
		set kpiClassName = ##class(%DeepSee.Utils).%GetKPIClass(key)
		
		do ..exportUDL(kpiClassName_".cls")
		set key = $order(listOfKPIs(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).exportDashboards()
ClassMethod exportDashboards() As %Status
{
	do ..fixDashIntoName()
	
	set sc = ##class(%DeepSee.Utils).%GetDashboardList(.listOfDashboards)
	
	set key = $order(listOfDashboards(""))
	
	while (key'="")
	{
		do ..exportDFIinXML(key_".DFI")
		set key = $order(listOfDashboards(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).exportPivots()
ClassMethod exportPivots() As %Status
{
	do ..fixDashIntoName()
	
	set sc = ##class(%DeepSee.Utils).%GetPivotList(.listOfPivots)
	
	set key = $order(listOfPivots(""))
	
	while (key'="")
	{
		do ..exportDFIinXML(key_".DFI")
		set key = $order(listOfPivots(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).checkAllPivots()
ClassMethod checkAllPivots() As %Status
{
	
	set sc = ##class(%DeepSee.Utils).%GetPivotList(.listOfPivots)
	
	set key = $order(listOfPivots(""))
	
	while (key'="")
	{
		do ..checkPivot(key)
		set key = $order(listOfPivots(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).checkPivot()
ClassMethod checkPivot(pivotFullName, debug = 1) As %Status
{
	do ##class(%DeepSee.Utils).%GetResultSetFromPivot(pivotFullName, .sc,1, .pParms)
	w:debug "Pivot: "_pivotFullName,!
	w:debug "Status: "_$system.Status.DisplayError(sc),!
	return sc
}

/// do ##class(dev.bi).checkDashboards()
ClassMethod checkDashboards() As %Status
{
	set sc = ##class(%DeepSee.Utils).%GetDashboardList(.listOfDashboards)
	
	set key = $order(listOfDashboards(""))
	
	while (key'="")
	{
		do ..checkDashboard(key)
		set key = $order(listOfDashboards(key))
	}

	return $$$OK
}

/// do ##class(dev.bi).checkDashboard("Basic Dashboard Demo.dashboard")
ClassMethod checkDashboard(dashboardName) As %Status
{
	Set dashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(dashboardName,.tSC)
	for i=1:1:dashboard.widgets.Count() 
	{
		set widget = dashboard.widgets.GetAt(i)
		set pivotFullName= widget.dataSource

		set cubeName = ..getCubeNameByPivot(pivotFullName)
		w !,"Cube name: "_cubeName,!
		w "Pivot name: "_ pivotFullName,!
		set pivotSC = ..checkPivot(pivotFullName,0)
		
		if $$$ISERR(pivotSC)
		{
			w "Pivot status: ",$system.Status.GetErrorText(pivotSC),!!
		}
		else
		{
			w "Pivot status: OK!",!!
		}

		for j=1:1:widget.controls.Count()
		{
			set control = widget.controls.GetAt(j)
			set action = control.action
			set targetProperty = control.targetProperty
			set label = control.label
			
			if (action = "setFilter") || (action = "applyFilter")
			{
				set sc = ##class(%DeepSee.Utils).%GetDimensionInfo(cubeName, targetProperty)
				set error = $system.Status.GetErrorText(sc)
				w "Filter name: "_label,!
				w "Status: "_$s($$$ISERR(sc): error,1: "OK!"),!
			}
		}
	}
 	return $$$OK
}

ClassMethod getCubeNameByPivot(pivotFullName) As %String
{
	set mdx = ##class(%DeepSee.Utils).%GetMDXFromPivot(pivotFullName,,0)
	set cubeName = $p(mdx," FROM ", 2)
	set cubeName = $replace(cubeName,"[","")
	set cubeName = $replace(cubeName,"]","")
	return cubeName
}

ClassMethod getSourceClass(pCubeName As %String) As %String
{
  Quit $G(^DeepSee.Cubes("cubes",$$$UPPER(pCubeName),"sourceClass"))
}

ClassMethod exportUDL(itemName As %String) As %Status
{
	set filename = ##class(dev.code).filename(itemName)
	do ##class(dev.code).mkdir( filename )
	
	write !, itemName, " -> ", $piece(filename,##class(dev.code).workdir(),2), " "
	
	set sc = $system.OBJ.ExportUDL(itemName, filename,"/diffexport") 
	write:sc "Ok" do:'sc $system.OBJ.DisplayError(sc)
	
	return sc
}

ClassMethod exportDFIinXML(itemName As %String) As %Status
{
	set filename = ##class(dev.code).filename(itemName)
	do ##class(dev.code).mkdir( filename )
	
	write !, itemName, " -> ", $piece(filename,##class(dev.code).workdir(),2), " "
	
	set documentName = $replace(itemName,"/","-")
	set filename = $extract(filename,1,*-4)
	do ..exportXML(documentName,filename_".xml")
	
	return $$$OK
}

/// do ##class(dev.bi).exportDeepSeeArtefacts()
ClassMethod exportDeepSeeArtefacts() As %Status
{
	set sc = $$$OK
	set artefacts = $listbuild("DeepSee.Variables","DeepSee.TermList","DeepSee.CalcMbrs")
	
	for i=1:1:$listlength(artefacts)
	{
		set artefact = $list(artefacts,i)
		continue:$data(@("^"_artefact))=0
		
		set artefact = artefact_".GBL"
		set filename = ##class(dev.code).filename(artefact)
		do ##class(dev.code).mkdir(filename)

		//without .gbl in the file name
		set filename = $e(filename,1, *-4)

		set sc = ..exportXML(artefact, filename_".xml")
	}

	return sc
}

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

/// do ##class(dev.bi).exportXML()
ClassMethod exportXML(documentName, filename) As %Status
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

}
