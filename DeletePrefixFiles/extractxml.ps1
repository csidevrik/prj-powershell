function Extract-XMLContent {
    param (
        [Parameter (Mandatory=$false)][string] $FolderPath    
    )
    # Specifies a path to one or more locations.
   

    $xmlC = Get-Content -Path $FolderPath -Raw

    # Declara el texto  del inicio y el fin para la extraccion
    $startLimit = '<infoTributaria>'
    $endLimit = '</infoAdicional>'

    #Encontrar los indices de inicio y fin
    $startIndex = $xmlC.IndexOf($startLimit)
    $endIndex   = $xmlC.IndexOf($endLimit,$startIndex)

    #Extrae la parte deseada del contenido
    $extractedXML = $xmlC.Substring($startIndex, $endIndex-$startIndex + $endLimit.Length)
    $extractedXMLFac = "<factura>`n$extractedXML`n</factura>"


    $estab = Select-Xml -Content $extractedXMLFac -XPath "//estab" 
    $ptoEm = Select-Xml -Content $extractedXMLFac -XPath "//ptoEmi"
    $secue =  Select-Xml -Content $extractedXMLFac -XPath "//secuencial"
    $codig = (Select-Xml -Content $extractedXMLFac -XPath '//campoAdicional[@nombre="Instalacion"]').Node.InnerText

    # Crear el nuevo nombre
    $newname = "FAC$estab$ptoEm$secue-$codig"

    # Rename-Item -Path $FolderPath -NewName "$newname.xml" -Force
    write-host $newname
    return $newname
}

function Main {
    $abc = Extract-XMLContent -FolderPath "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD\test\FAC052884737_001.xml"
    write-host $abc
}

Main