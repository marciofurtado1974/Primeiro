#Include "Protheus.ch"
#Include "FwMVCDef.ch"

/*/{Protheus.doc} HistFasC
    Tela para apresentação de dados de histórico do envio da integração de títulos à FastConnect ou Excelência
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 23/09/2021
    @param cNumCont, character, Numero do título
    @param _cPrefixo, character, Número do prefixo
    @param _cParcela, character, Número da parcela
    @param cCliente, character, Código do cliente
    @param cLoja, character, Código da loja
    /*/
User Function HistFCCC(cNumCont, cCliente, cLoja)

    Local cEspaco      := Replicate(" ", 5)
    Local cNomeCli     := AllTrim(Posicione("SA1", 1, FWxFilial("SA1") + cCliente + cLoja, "A1_NREDUZ"))
    Local _cDescCab     := ""
    // tipo do título
    // Private cTipoTit    := AllTrim(SE1->E1_TIPO)
    Private cTabIntegFC := "Z10"
    Private cTabIntegEx := ""

    // título da tela
    _cDescCab += "<strong>Contrato:</strong> " + AllTrim(cNumCont) + cEspaco
    _cDescCab += "<strong>Cliente/Loja:</strong> " + AllTrim(cCliente) + "/" + AllTrim(cLoja) + " - " + cNomeCli

	FWExecView(_cDescCab, "VIEWDEF.LOGFSTCC", MODEL_OPERATION_VIEW,,,,50)
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
	oStrGrid := FWFormStruct(1, "Z10")

    // remove campos que não serão exibidos
    oStrGrid:RemoveField("Z10_FILIAL")
    oStrGrid:RemoveField("Z10_TIPTIT")

    // campos de status
    oStrGrid:AddField('',                       'Imagem',     'IMAGEM',  'C',4,,,,,,{|| },, .F. )
    // If !Empty(cTabIntegFC)
    //     oStrGrid:AddField(FWX3Titulo(cTabIntegFC+"_LINKCP"),   '', (cTabIntegFC+"_LINKCP"),  'C',TamSX3(cTabIntegFC+"_LINKCP")[1],,,,,,{|| },, .F. )
    // EndIf

	oModel := MPFormModel():New("LOGFSTCM")
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
        If At(cTabIntegFC+"_LINKCP", cFields) > 0
            cFields := StrTran(cFields, (cTabIntegFC+"_LINKCP"), "(CASE WHEN Z10_STATUS = 'R' THEN " + cTabIntegFC + "_LINKCP ELSE '' END) AS " + cTabIntegFC+"_LINKCP")
        EndIf
    EndIf

    If At("IMAGEM", cFields) > 0
        // P=Pendente retorno; A=Aprovado cartão ; F=Erro
        cImagens := " WHEN Z10_STATUS = 'A' THEN 'DESTINOS.PNG' "   // Aprovado
        cImagens += " WHEN Z10_STATUS = 'P' THEN 'GCTPIMST.PNG' "   // Pendente retorno
        cImagens += " ELSE 'DBG09.PNG' "                            // Erro
        cFields := StrTran(cFields, "IMAGEM", "(CASE " + cImagens + " END) as IMAGEM")
    EndIf

    // consulta de logs do título
	cQuery := " SELECT " + cFields + ", Z10.R_E_C_N_O_ RECNO "
	cQuery += " FROM "+RetSqlTab("Z10")
	cQuery += " WHERE Z10_FILIAL = '" + FWxFilial("Z10") + "' "
	cQuery += " AND Z10_CONTRA = '" + SZC->ZC_NUM + "' "
	cQuery += " AND Z10_CLIENT = '" + SZC->ZC_CLIENTE + "' "
	cQuery += " AND Z10_LOJA   = '" + SZC->ZC_LOJA + "' "
    // busca integração somente da Fast
    // If !Empty(cTabInteg)
	//     cQuery += " AND Z10_TIPTIT IN (" + If(AllTrim(cTipoTit) != "CC", "'BOL', 'NF'", "'CC'") + ") "
    // // busca integração da Fast e Excelência
    // Else
    // EndIf
	cQuery += " AND Z10.D_E_L_E_T_ <> '*' "
	cQuery += " ORDER BY Z10_DATA || Z10_HORA DESC "
	cQuery := ChangeQuery(cQuery)

	DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAlias, .F., .T.)

    For nX := 1 To Len(oModel:aHeader)
        If oModel:aHeader[nX][8] != "C"
            TcSetField(cAlias, oModel:aHeader[nX][2], oModel:aHeader[nX][8], oModel:aHeader[nX][4], oModel:aHeader[nX][5])
        EndIf
    Next nX

	aData := FwLoadByAlias(oModel, cAlias, "Z10", "RECNO", /*lCopy*/, .T.)

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
    Local cCampoLink := cTabIntegFC + "_LINKCP"
    Local lCopyClpBo := .T.

	// estrutura fake do cabeçalho
	oStrCab := FWFormViewStruct():New()
	oStrCab:addField("C_STRING1", "01" , "String 01", "Campo de texto", , "C" )

	// estrutura de grid
	oStrGrid := FWFormStruct(2, "Z10")
    
    // remove campos que não serão utilizados
    oStrGrid:RemoveField("Z10_FILIAL")
    oStrGrid:RemoveField("Z10_TITULO")
    oStrGrid:RemoveField("Z10_PREFIX")
    oStrGrid:RemoveField("Z10_PARCEL")
    oStrGrid:RemoveField("Z10_CLIENT")
    oStrGrid:RemoveField("Z10_LOJA")
    oStrGrid:RemoveField("Z10_TIPTIT")
    oStrGrid:RemoveField("Z10_STATUS")
        
    // campos de status
    oStrGrid:AddField('IMAGEM',     '01','',                      'Imagem',      {},"C","@BMP",{||},"",.F.,,,,,, .F. )
    // If !Empty(cTabIntegFC)
    //     oStrGrid:AddField(cCampoLink, '10',FWX3Titulo(cCampoLink), 'Link Pagamento',{},'C',"",  {||},"",.F.,,,,,, .F. )
    // EndIf

    // altera tamanho visual do campo da mensagem
    oStrGrid:SetProperty("Z10_MENSAG", MVC_VIEW_WIDTH, (TamSX3("Z10_MENSAG")[1]*3)) // Tamanho 300
    If !Empty(cTabIntegFC)
        oStrGrid:SetProperty(cCampoLink, MVC_VIEW_WIDTH, (TamSX3(cCampoLink)[1]*3.5)) // Tamanho 300
    EndIf

	oModel   := FWLoadModel("LOGFSTCC")
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
    Local cCampoLink := cTabIntegFC + "_LINKCP"
    // modelo de dados
    Local oModel     := FwModelActive()

    If cFieldName == cCampoLink
        // copia a informação do campo para a área de transferência
        CopytoClipboard(AllTrim(oModel:GetValue("GRIDID", cFieldName)))
        lRet := .T.
    EndIf
    
Return lRet
