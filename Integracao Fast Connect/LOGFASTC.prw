#Include "Protheus.ch"
#Include "FwMVCDef.ch"

/*/{Protheus.doc} HistFasC
    Tela para apresentação de dados de histórico do envio da integração de títulos à FastConnect ou Excelência
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @param _cNumTit, character, Numero do título
    @param _cPrefixo, character, Número do prefixo
    @param _cParcela, character, Número da parcela
    @param _cCliente, character, Código do cliente
    @param _cLoja, character, Código da loja
    /*/
User Function HistFasC(_cNumTit, _cPrefixo, _cParcela, _cCliente, _cLoja)

    Local _cEspaco      := Replicate(" ", 5)
    Local _cNomeCli     := AllTrim(Posicione("SA1", 1, FWxFilial("SA1") + _cCliente + _cLoja, "A1_NREDUZ"))
    Local _cDescCab     := ""
    // tipo do título
    Private cTipoTit    := AllTrim(SE1->E1_TIPO)
    Private cTabIntegFC := ""
    Private cTabIntegEx := ""

    // busca contrato se existir
    If !Empty(SE1->E1_CONTKHR)
        Dbselectarea("SZC")
        SZC->(DbSetOrder(1))
        If SZC->(DbSeek(xFilial("SZC") + SE1->E1_CONTKHR))
            cTipoTit := SZC->ZC_FORMA
        EndIf
    EndIf

    // se chamada vier do monitor da Excelência não exibe Fast Connect
    If !IsInCallStack("U_KHREXINT")
        // Fast Connect
        If AllTrim(cTipoTit) == "CC"
            // cartão de crédito
            cTabIntegFC := "Z05"

        Else
            // boleto
            cTabIntegFC := "Z04"
        EndIf
        
        // verifica se a tabela existe para a empresa
        If !TCCanOpen(RetSQLName(cTabIntegFC))
            cTabIntegFC := ""
        EndIf
    EndIf

    // se chamada vier do monitor da Fast Connect não exibe Excelência
    If !IsInCallStack("U_KHRFCINT")
        // Excelência
        cTabIntegEx := "Z07"

        // verifica se a tabela existe para a empresa
        If !TCCanOpen(RetSQLName(cTabIntegEx))
            cTabIntegEx := ""
        EndIf
    EndIf

    // título da tela
    _cDescCab += "<strong>Num:</strong> " + AllTrim(_cNumTit) + _cEspaco
    _cDescCab += "<strong>Prefixo:</strong> " + AllTrim(_cPrefixo) + _cEspaco
    _cDescCab += "<strong>Parcela:</strong> " + AllTrim(_cParcela) + _cEspaco
    _cDescCab += "<strong>Cliente/Loja:</strong> " + AllTrim(_cCliente) + "/" + AllTrim(_cLoja) + " - " + _cNomeCli

	FWExecView(_cDescCab, "VIEWDEF.LOGFASTC", MODEL_OPERATION_VIEW,,,,50)
Return Nil


/*/{Protheus.doc} ModelDef
    Montagem do modelo dados para MVC
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @return oModel - Objeto do modelo de dados
    /*/
Static function ModelDef()

	local oModel            as object
	local oStrField         as object
	local oStrGrid          as object

	// estrutura Fake de Field
	oStrField := FWFormModelStruct():New()

	oStrField:addTable("", {"C_STRING1"}, "Log de integração Fast Connect", {|| "" })
	oStrField:addField("String 01", "Campo de texto", "C_STRING1", "C", 15)
        
	// estrutura de Grid, alias Real presente no dicionário de dados
	oStrGrid := FWFormStruct(1, "Z03")

    // remove campos que não serão exibidos
    oStrGrid:RemoveField("Z03_FILIAL")
    oStrGrid:RemoveField("Z03_TIPTIT")

    // campos de status
    oStrGrid:AddField('',                       'Imagem',     'IMAGEM',  'C',4,,,,,,{|| },, .F. )
    If !Empty(cTabIntegFC)
        oStrGrid:AddField(FWX3Titulo(cTabIntegFC+"_LINKPG"),   '', (cTabIntegFC+"_LINKPG"),  'C',TamSX3(cTabIntegFC+"_LINKPG")[1],,,,,,{|| },, .F. )
    EndIf

	oModel := MPFormModel():New("LOGFASTM")
	oModel:addFields("CABID", /*cOwner*/, oStrField, /*bPre*/, /*bPost*/, {|oMdl| loadHidFld()})
	oModel:addGrid("GRIDID", "CABID", oStrGrid, /*bLinePre*/, /*bLinePost*/, /*bPre*/, /*bPost*/, {|oMdl| loadGrid(oMdl)})
	oModel:setDescription("Log de integração Fast Connect")
	// É necessário que haja alguma alteração na estrutura Field
	oModel:setActivate({ |oModel| onActivate(oModel)})

Return oModel

/*/{Protheus.doc} onActivate
    Função estática para o activate do model
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @param oModel, object, Objeto do modelo de dados
    /*/
Static Function onActivate(oModel)

	//Só efetua a alteração do campo para inserção
	If oModel:GetOperation() == MODEL_OPERATION_INSERT
		FwFldPut("C_STRING1", "FAKE" , /*nLinha*/, oModel)
	endif

Return

/*/{Protheus.doc} loadGrid
    Função estática para efetuar o load dos dados do grid
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @param oModel, object, Objeto do modelo de dados
    @return variant, return_description
    /*/
Static Function loadGrid(oModel)

	local aData     := {}   as array
    Local aFldConv  := {}   as array
	local cAlias    := GetNextAlias()   as char
	Local cQuery    := ""   as character
    Local nX
    Local cFields   := ATFFld2Str(oModel:GetStruct(),.F.,aFldConv,,,.T.)

    // altera busca do campo de link para trazer somente na linha em que ocorreu sucesso (Fast Recebeu o título)
    If !Empty(cTabIntegFC)
        If At(cTabIntegFC+"_LINKPG", cFields) > 0
            cFields := StrTran(cFields, (cTabIntegFC+"_LINKPG"), "(CASE WHEN Z03_STATUS = 'R' THEN " + cTabIntegFC + "_LINKPG ELSE '' END) AS " + cTabIntegFC+"_LINKPG")
        EndIf
    EndIf

    If At("IMAGEM", cFields) > 0
        // R=Recebido pela Fast; A=Alteração ; C=Cancelado ; B=Baixado ; E=Erro
        cImagens := " WHEN Z03_STATUS = 'R' THEN 'DESTINOS.PNG' "   // Recebido
        cImagens += " WHEN Z03_STATUS = 'A' THEN 'RECORRENTE.PNG' " // Alteração
        cImagens += " WHEN Z03_STATUS = 'C' THEN 'CANCEL.PNG' "     // Cancelado
        cImagens += " WHEN Z03_STATUS = 'B' THEN 'OK.PNG' "         // Baixado
        cImagens += " WHEN Z03_STATUS = 'T' THEN 'TABPRICE.PNG' "   // Pagamento via cartão de crédito aprovado
        cImagens += " ELSE 'DBG09.PNG' "                            // Erro
        cFields := StrTran(cFields, "IMAGEM", "(CASE " + cImagens + " END) as IMAGEM")
    EndIf

    // consulta de logs do título
	cQuery := " SELECT " + cFields + ", Z03.R_E_C_N_O_ RECNO "
	cQuery += " FROM "+RetSqlTab("Z03")
    // busca integração somente da Fast
    // If !Empty(cTabInteg)
    //     cQuery += " LEFT JOIN " + RetSqlTab(cTabInteg)
    //     cQuery += "     ON " + cTabInteg + "_FILIAL = Z03_FILIAL "
    //     cQuery += "     AND " + cTabInteg + "_TITULO = Z03_TITULO "
    //     cQuery += "     AND " + cTabInteg + "_PREFIX = Z03_PREFIX "
    //     cQuery += "     AND " + cTabInteg + "_PARCEL = Z03_PARCEL "
    //     cQuery += "     AND " + cTabInteg + "_CLIENT = Z03_CLIENT "
    //     cQuery += "     AND " + cTabInteg + "_LOJA   = Z03_LOJA "
    //     cQuery += "     AND " + cTabInteg + ".D_E_L_E_T_ <> '*' "
    // // busca integração da Fast e Excelência
    // Else
    // verifica se a tabela de integração com Excelência existe
    If !Empty(cTabIntegFC) .and. TCCanOpen(RetSQLName(cTabIntegFC))
        cQuery += " LEFT JOIN " + RetSqlTab(cTabIntegFC)
        cQuery += "     ON " + cTabIntegFC + "_FILIAL = Z03_FILIAL "
        cQuery += "     AND " + cTabIntegFC + "_TITULO = Z03_TITULO "
        cQuery += "     AND " + cTabIntegFC + "_PREFIX = Z03_PREFIX "
        cQuery += "     AND " + cTabIntegFC + "_PARCEL = Z03_PARCEL "
        cQuery += "     AND " + cTabIntegFC + "_CLIENT = Z03_CLIENT "
        cQuery += "     AND " + cTabIntegFC + "_LOJA   = Z03_LOJA "
        cQuery += "     AND " + cTabIntegFC + ".D_E_L_E_T_ <> '*' "
    EndIf

    // verifica se a tabela de integração com Excelência existe
    If !Empty(cTabIntegEX) .and. TCCanOpen(RetSQLName(cTabIntegEX))
        cQuery += " LEFT JOIN " + RetSqlTab(cTabIntegEX)
        cQuery += "     ON " + cTabIntegEX + "_FILIAL = Z03_FILIAL "
        cQuery += "     AND " + cTabIntegEX + "_TITULO = Z03_TITULO "
        cQuery += "     AND " + cTabIntegEX + "_PREFIX = Z03_PREFIX "
        cQuery += "     AND " + cTabIntegEX + "_PARCEL = Z03_PARCEL "
        cQuery += "     AND " + cTabIntegEX + "_CLIENT = Z03_CLIENT "
        cQuery += "     AND " + cTabIntegEX + "_LOJA   = Z03_LOJA "
        cQuery += "     AND " + cTabIntegEX + ".D_E_L_E_T_ <> '*' "
    EndIf
    // EndIf
	cQuery += " WHERE Z03_FILIAL = '" + FWxFilial("Z03") + "' "
	cQuery += " AND Z03_TITULO = '" + SE1->E1_NUM + "' "
	cQuery += " AND Z03_PREFIX = '" + SE1->E1_PREFIXO + "' "
	cQuery += " AND Z03_CLIENT = '" + SE1->E1_CLIENTE + "' "
	cQuery += " AND Z03_LOJA   = '" + SE1->E1_LOJA + "' "
	cQuery += " AND Z03_PARCEL = '" + SE1->E1_PARCELA + "' "
    // busca integração somente da Fast
    // If !Empty(cTabInteg)
	//     cQuery += " AND Z03_TIPTIT IN (" + If(AllTrim(cTipoTit) != "CC", "'BOL', 'NF'", "'CC'") + ") "
    // // busca integração da Fast e Excelência
    // Else
	    cQuery += " AND Z03_TIPTIT IN (" + If(AllTrim(cTipoTit) != "CC", "'BOL'", "'CC'") + ", 'EXC') "
    // EndIf
	cQuery += " AND Z03.D_E_L_E_T_ <> '*' "
	cQuery += " ORDER BY Z03_DATA || Z03_HORA DESC "
	cQuery := ChangeQuery(cQuery)

	DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAlias, .F., .T.)

    For nX := 1 To Len(oModel:aHeader)
        If oModel:aHeader[nX][8] != "C"
            TcSetField(cAlias, oModel:aHeader[nX][2], oModel:aHeader[nX][8], oModel:aHeader[nX][4], oModel:aHeader[nX][5])
        EndIf
    Next nX

	aData := FwLoadByAlias(oModel, cAlias, "Z03", "RECNO", /*lCopy*/, .T.)

return aData

/*/{Protheus.doc} loadHidFld
    Função estática para load dos dados do field escondido
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @param oModel, object, Objeto do modelo de dados
    @return variant, return_description
    /*/
Static Function loadHidFld(oModel)
Return {""}

/*/{Protheus.doc} viewDef
    Função estática do ViewDef
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @return variant, Objeto da view, interface
    /*/
static function ViewDef()

	local oView      as object
	local oModel     as object
	local oStrCab    as object
	local oStrGrid   as object
    Local cCampoLink := cTabIntegFC + "_LINKPG"
    Local lCopyClpBo := .T.

	// estrutura fake do cabeçalho
	oStrCab := FWFormViewStruct():New()
	oStrCab:addField("C_STRING1", "01" , "String 01", "Campo de texto", , "C" )

	// estrutura de grid
	oStrGrid := FWFormStruct(2, "Z03")
    
    // remove campos que não serão utilizados
    oStrGrid:RemoveField("Z03_FILIAL")
    oStrGrid:RemoveField("Z03_TITULO")
    oStrGrid:RemoveField("Z03_PREFIX")
    oStrGrid:RemoveField("Z03_PARCEL")
    oStrGrid:RemoveField("Z03_CLIENT")
    oStrGrid:RemoveField("Z03_LOJA")
    oStrGrid:RemoveField("Z03_TIPTIT")
    oStrGrid:RemoveField("Z03_STATUS")
        
    // campos de status
    oStrGrid:AddField('IMAGEM',     '01','',                      'Imagem',      {},"C","@BMP",{||},"",.F.,,,,,, .F. )
    If !Empty(cTabIntegFC)
        oStrGrid:AddField(cCampoLink, '10',FWX3Titulo(cCampoLink), 'Link Pagamento',{},'C',"",  {||},"",.F.,,,,,, .F. )
    EndIf

    // altera tamanho visual do campo da mensagem
    oStrGrid:SetProperty("Z03_MENSAG", MVC_VIEW_WIDTH, (TamSX3("Z03_MENSAG")[1]*3)) // Tamanho 300
    If !Empty(cTabIntegFC)
        oStrGrid:SetProperty(cCampoLink, MVC_VIEW_WIDTH, (TamSX3(cCampoLink)[1]*3.5)) // Tamanho 300
    EndIf

	oModel   := FWLoadModel("LOGFASTC")
	oView    := FwFormView():New()

	oView:SetModel(oModel)
	oView:AddField("CAB", oStrCab, "CABID")
	oView:AddGrid("GRID", oStrGrid, "GRIDID")
	oView:CreateHorizontalBox("TOHIDE", 0 )
	oView:CreateHorizontalBox("TOSHOW", 100 )
	oView:SetOwnerView("CAB", "TOHIDE" )
	oView:SetOwnerView("GRID", "TOSHOW")
	oView:SetDescription( "Log de integração Fast Connect" )

    // duplo clique na grid, copia campo de link para a área de transferência
	oView:SetViewProperty("GRID", "GRIDDOUBLECLICK", {{|oGrid, cFieldName, nLineGrid, nLineModel| lCopyClpBo := DblClickGrid(oGrid, cFieldName, nLineGrid, nLineModel), If(lCopyClpBo, FWAlertSucess("Copiado para área de transferência..."),) }})

return oView

/*/{Protheus.doc} DblClickGrid
    Ação do clicque duplo na grid
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 22/10/2021
    @param oGrid, object, View da grid
    @param cFieldName, character, Campo clicado
    @param nLineGrid, numeric, Linha da grid clicada
    @param nLineModel, numeric, Linha do model
    @return variant, return_description
    /*/
Static Function DblClickGrid(oGrid, cFieldName, nLineGrid, nLineModel)

    Local lRet       := .F.
    // campo para cópia
    Local cCampoLink := cTabIntegFC + "_LINKPG"
    // modelo de dados
    Local oModel     := FwModelActive()

    If cFieldName == cCampoLink
        // copia a informação do campo para a área de transferência
        CopytoClipboard(AllTrim(oModel:GetValue("GRIDID", cFieldName)))
        lRet := .T.
    EndIf
    
Return lRet
