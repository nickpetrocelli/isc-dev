Class sc.diff.utils
{

Parameter TRACKEDEXT As List = {$lb("xml", "cls", "csp", "csr", "mac", "int", "bas", "inc", "gbl", "prj", "obj", "pkg", "gof", "dfi", "pivot", "dashboard")};

ClassMethod ToCacheName(ByRef FileName)
{
	set:$L(FileName,".xml")'=1 FileName = $extract(FileName,1,*-4)
	set str = $Select($L(FileName,"cls/")>1:$Replace($P(FileName,"cls/",2),"/","."),
	    $L(FileName,"csp/")>1:$Replace($P(FileName,"csp/",2),"/","."),
	    $L(FileName,"dfi/")>1:$Replace($P(FileName,"dfi/",2),"/","-"),
	    $L(FileName,"inc/")>1:$Replace($P(FileName,"inc/",2),"/","."),
	    $L(FileName,"web/")>1:$Replace($P(FileName,"web/",2),"/","."),
	    1:$Replace(FileName,"/",".")
	   )
	set FileName = $P(str,".",1,*-1)_"."_ $ZCVT($P(str,".",*),"U")
}

ClassMethod isRelevantFile(file As %String) As %Boolean
{
	set ext = $select($length(file, ".")=1:"", 1:$piece(file, ".", *))
	quit $lf(..#TRACKEDEXT, ext)>0
}

}

