//Bibliotecas
#Include 'Protheus.ch'
#include "FwMBrowse.ch"
#Include 'FwMVCDef.ch'

#Define enter Chr(13) + Chr(10)

/*/{Protheus.doc} KHRFCINT
    Tela de monitor para visualização e títulos integrados com a Fast Connect (Boleto e Cartão de crédito)
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 07/10/2021
    @return Nil
    /*/
User Function KHRFCINT()

	Local aArea        := GetArea()
	Private oBrowse
	Private oTableAtt
	Private cTitulo    := "Integração de títulos x Fast Connect."
	Private oModal
	Private cFiltro    := ""
	Private aOpcFiltro := {"1=Todos", "2=Integrados", "3=Com Erro", "4=Cancelados", "5=Aguardando Integração"}

	// AxCadastro("Z04", "", ".t.")
	
	// tela inicial de filtro
	oModal  := FWDialogModal():New()
    oModal:SetEscClose(.T.)
    oModal:SetTitle("Selecione o filtro: ")
     
    // seta a largura e altura da janela em pixel
    oModal:SetSize(100, 150)

    oModal:CreateDialog()

	oModal:AddButton('Confirmar', {|| oModal:DeActivate() }, 'Confirmar',, .T., .F., .T.,)

	oContainer := TPanel():New( ,,, oModal:GetPanelMain() )
    oContainer:Align := CONTROL_ALIGN_ALLCLIENT
	oCombo1 := TComboBox():New(05,05,{|u|if(PCount()>0,cFiltro:=u,cFiltro)},aOpcFiltro,100,20,oContainer,,{||},,,,.T.,,,,,,,,,'cFiltro')

	// ativa dialog
    oModal:Activate()


	// instânciando FWMBrowse
	oBrowse := FWMBrowse():New()

	oBrowse:SetAlias("SE1")
	oBrowse:DisableDetails()

	oBrowse:SetFilterDefault(" !Empty(E1_ZSTATFC) ")    // Somente com algum status de integração

	// filtro
	If cFiltro == "1"
		// oBrowse:SetFilterDefault(" !Empty(E1_ZSTATFC) ")
		// oBrowse:ExecuteFilter()
	ElseIf cFiltro == "2"
		// oBrowse:SetFilterDefault(" E1_ZSTATFC == 'I' ")
		// oBrowse:ExecuteFilter()
		oBrowse:SetIDViewDefault("TitIntegr")
	ElseIf cFiltro == "3"
		// oBrowse:SetFilterDefault(" E1_ZSTATFC == 'E' ")
		// oBrowse:ExecuteFilter()
		oBrowse:SetIDViewDefault("TitErro")
	ElseIf cFiltro == "4"
		// oBrowse:SetFilterDefault(" E1_ZSTATFC == 'C' ")
		// oBrowse:ExecuteFilter()
		oBrowse:SetIDViewDefault("TitCancel")
	ElseIf cFiltro == "5"
		// oBrowse:SetFilterDefault(" E1_ZSTATFC == 'P' ")
		// oBrowse:ExecuteFilter()
		oBrowse:SetIDViewDefault("TitAguard")
	EndIf

	// legenda dos orçamentos
	// adiciona legenda da baixa, pois não tem por padrão conforme a tela de contas a receber
	oBrowse:AddLegend("E1_ZSTATFC == 'B' .or. E1_SALDO == 0 ", "BR_VERMELHO",  "Título baixado")
	oBrowse:AddLegend("E1_ZSTATFC == 'P' ", "GCTPIMST.PNG",  "Aguardando envio à Fast Connect")
	// oBrowse:AddLegend("E1_ZSTATFC == 'S' ", "ATALHO.PNG",  	 "Título enviado à Fast Connect")
	oBrowse:AddLegend("E1_ZSTATFC == 'R' ", "DESTINOS.PNG",  "Título recebido pela Fast Connect")
	oBrowse:AddLegend("E1_ZSTATFC == 'E' ", "DBG09.PNG",     "Erro na integração com a Fast Connect")
	oBrowse:AddLegend("E1_ZSTATFC == 'C' ", "CANCEL.PNG",    "Aguardando cancelamento do título à Fast Connect")
	// oBrowse:AddLegend("E1_ZSTATFC == 'V' ", "BTCALEND.PNG",  "Alteração de vencimento. Aguardando envio para Fast Connect")
	oBrowse:AddLegend("E1_ZSTATFC == 'A' ", "ALTERA.PNG",  "Alteração de dados. Aguardando envio para Fast Connect")
	oBrowse:AddLegend("E1_ZSTATFC == 'T' ", "TABPRICE.PNG",  "Pagamento via cartão de crédito aprovado")

    // título do browse
	oBrowse:SetDescription(cTitulo)

    // menu
	oBrowse:SetMenuDef('KHRFCINT')

	// informa que devem aparecer registros deletados (cancelados)
	// oBrowse:SetDelete(.F., )

	// adiciona filtros
	oTableAtt := TableAttDef()
	oBrowse:SetAttach(.T.)
	oBrowse:SetViewsDefault(oTableAtt:aViews)


    // refresh automatico a cada 5 minutos
    // TODO alterar para verificar horário
    oBrowse:SetTimer({|| oBrowse:Refresh(), (5*60*1000) })



// -------------------------------------------------------------
    // _cTempTbl   := GetNextAlias()


	// // cria índice
	// aAdd(_aIndex, {"E1_NUM", "E1_PREFIXO", "E1_CLIENTE", "E1_LOJA"})

	// // cria o arquivo de trabalho
	// oTable := FWTemporaryTable():New(_cTempTbl)
	// oTable:SetFields(_aStruHead)
	// oTable:AddIndex("01", _aIndex[1])
	// oTable:Create()

    // cFields := ""
    // For i := 1 to Len(_aStruHead)
	// 	cFields += _aStruHead[i][1] + ","
	// Next i
	// cFields := Left(cFields, Len(cFields)-1)

    // // busca dados da tabela genérica
	// _cQuery := " SELECT " + cFields
	// _cQuery += " FROM " + RetSqlTab("SE1")
	// _cQuery += " WHERE E1_FILIAL = '" + FWxFilial("SE1") + "' "

    // _cAliasTmp := GetNextAlias()
	// // DbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAliasTmp), .F., .T.)

	// MPSysOpenQuery( _cQuery, (_cAliasTmp), _aStruHead )

    // //Criação do insert into
	// // cQueryIns := "INSERT INTO " + oTable:GetRealName()
	// // cQueryIns += " (" + cFields + ") "
	// // cQueryIns += _cQuery

    // // TCSqlExec(cQueryIns)

	// DbSelectArea(_cAliasTmp)
	// DbSelectArea(_cTempTbl)
	// (_cAliasTmp)->(DbGoTop())
    // While ! (_cAliasTmp)->(Eof())
    //     RecLock(_cTempTbl, .T.)
    //         For i := 1 To Len(_aStruHead)
    //             If _aStruHead[i, 2] == "D"
    //                 (_cTempTbl)->&(_aStruHead[i, 1]) := SToD((_cAliasTmp)->&(_aStruHead[i, 1]))
    //             Else
    //                 (_cTempTbl)->&(_aStruHead[i, 1]) := (_cAliasTmp)->&(_aStruHead[i, 1])
    //             Endif
    //         Next
    //     (_cTempTbl)->(MsUnlock())
    //     (_cAliasTmp)->(DbSkip())
    // End

	// DbSelectArea(_cAliasTmp)
	// // IndRegua((_cAliasTmp), (oTable), "E1_NUM+E1_PREFIXO+E1_CLIENTE+E1_LOJA", , , "Selecionando Registros...")
	// // (_cAliasTmp)->(dbSetIndex((oTable) + OrdBagExt()))

	// // posiciona no inicio da tabela
	// (_cAliasTmp)->(DbGoTop())



    // oBrowse:SetAlias(_cAliasTmp)
	// oBrowse:SetQueryIndex(_aIndex)
	// oBrowse:SetFields(_aBrwHead)
	// oBrowse:SetTemporary(.T.)
// -------------------------------------------------------------

	// ativa o browse
	oBrowse:Activate()

	RestArea(aArea)

Return Nil

/*/{Protheus.doc} MenuDef
    Menu da rotina
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 07/10/2021
    @return aRotina, Array de botões
    /*/
Static Function MenuDef()
	Local aRotina := {}

	// ADD OPTION aRotina TITLE "Pesquisar"  	ACTION 'PesqBrw'          	OPERATION 1 ACCESS 0
	// ADD OPTION aRotina TITLE 'Liberar'  	ACTION 'VIEWDEF.KHRFCINT' 	OPERATION 4 ACCESS 0 //OPERATION 4
	ADD OPTION aRotina TITLE 'Visualizar' 				ACTION 'VIEWDEF.KHRFCINT' 			OPERATION 2 ACCESS 0 //OPERATION 1
	ADD OPTION aRotina TITLE "Histórico"				ACTION 'U_HistFasC(SE1->E1_NUM, SE1->E1_PREFIXO, SE1->E1_PARCELA, SE1->E1_CLIENTE, SE1->E1_LOJA)' 		OPERATION MODEL_OPERATION_VIEW 	 ACCESS 0 //OPERATION 5
	ADD OPTION aRotina TITLE 'Reenvio do título atual'	ACTION 'U_ReenvTitFC(1)' 			OPERATION MODEL_OPERATION_VIEW 	 ACCESS 0 //OPERATION 5
	ADD OPTION aRotina TITLE 'Reenvio de todos os títulos com erro'    	ACTION 'U_ReenvTitFC(2)' 		OPERATION MODEL_OPERATION_VIEW 	 ACCESS 0 //OPERATION 5
	ADD OPTION aRotina TITLE 'Legenda'    				ACTION 'U_FCIntLeg()' 				OPERATION MODEL_OPERATION_VIEW 	 ACCESS 0 //OPERATION 5

Return aRotina


/*/{Protheus.doc} TableAttDef
    Cria visões da tela (filtro dos status)
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 07/10/2021
    @return variant, return_description
    /*/
Static Function TableAttDef()

	Local oTableAtt		:= Nil
	Local oTitAguard	:= Nil // Títulos Aguardando Integração
	Local oTitIntegr	:= Nil // Títulos Integrados
	Local oTitErro		:= Nil // Títulos com Erro
	Local oTitCancel	:= Nil // Títulos Cancelados
    Local aFieldsBrw    := {Nil}    // Adiciona campo inicial para legenda

    // campos do browse
    DbSelectArea("SX3")
    SX3->(DbSetOrder(1))    // X3_ARQUIVO
    If SX3->(DbSeek("SE1"))
        While ! SX3->(Eof()) .And. AllTrim(SX3->X3_ARQUIVO) == "SE1"
            If (X3Uso(SX3->X3_USADO) .And. AllTrim(SX3->X3_BROWSE) == "S") .or. AllTrim(SX3->X3_CAMPO) == "E1_ZSTATFC"
                aAdd(aFieldsBrw, SX3->X3_CAMPO)

                // define a estrutura da tabela
                // aAdd(_aStruHead,{SX3->X3_CAMPO  ,SX3->X3_TIPO ,SX3->X3_TAMANHO   ,SX3->X3_DECIMAL})

                // define o header do browse
                // aAdd(_aBrwHead, {SX3->X3_TITULO ,SX3->X3_CAMPO ,SX3->X3_TIPO ,SX3->X3_TAMANHO   ,SX3->X3_DECIMAL ,SX3->X3_PICTURE})
            EndIf
            SX3->(DbSkip())
        End
    EndIf

	oTableAtt := FWTableAtt():New()
	oTableAtt:SetAlias("SE1")
    
	// Títulos Aguardando Integração
	oTitAguard := FWDSView():New()
	oTitAguard:SetName("Títulos Aguardando Integração")
	oTitAguard:SetID("TitAguard")
	oTitAguard:SetOrder(1) // E1_FILIAL + E1_NUM + E1_CLIENTE + E1_LOJA
	oTitAguard:SetCollumns(aFieldsBrw)
	oTitAguard:SetPublic( .T. )
	// oTitAguard:AddFilter("Títulos Aguardando Integração", "E1_ZSTATFC == 'P' .or. E1_ZSTATFC == 'S'")
	oTitAguard:AddFilter("Títulos Aguardando Integração", "E1_ZSTATFC == 'P'")
	oTableAtt:AddView(oTitAguard)

	// Títulos Integrados
	oTitIntegr := FWDSView():New()
	oTitIntegr:SetName("Títulos Integrados")
	oTitIntegr:SetID("TitIntegr")
	oTitIntegr:SetOrder(1) // E1_FILIAL + E1_NUM + E1_CLIENTE + E1_LOJA
	oTitIntegr:SetCollumns(aFieldsBrw)
	oTitIntegr:SetPublic( .T. )
	oTitIntegr:AddFilter("Títulos Integrados", "E1_ZSTATFC == 'R'")
	oTableAtt:AddView(oTitIntegr)

	// Títulos com Erro
	oTitErro := FWDSView():New()
	oTitErro:SetName("Títulos com Erro")
	oTitErro:SetID("TitErro")
	oTitErro:SetOrder(1) // E1_FILIAL + E1_NUM + E1_CLIENTE + E1_LOJA
	oTitErro:SetCollumns(aFieldsBrw)
	oTitErro:SetPublic( .T. )
	oTitErro:AddFilter("Títulos com Erro", "E1_ZSTATFC == 'E'")
	oTableAtt:AddView(oTitErro)

	// Títulos Cancelados
	oTitCancel := FWDSView():New()
	oTitCancel:SetName("Títulos Cancelados")
	oTitCancel:SetID("TitCancel")
	oTitCancel:SetOrder(1) // E1_FILIAL + E1_NUM + E1_CLIENTE + E1_LOJA
	oTitCancel:SetCollumns(aFieldsBrw)
	oTitCancel:SetPublic( .T. )
	oTitCancel:AddFilter("Títulos Cancelados", "E1_ZSTATFC == 'C'")
	oTableAtt:AddView(oTitCancel)

Return (oTableAtt)

/*/{Protheus.doc} ModelDef
    Modelo de dados
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 07/10/2021
    @return variant, return_description
    /*/
Static Function ModelDef()
	Local oModel       := Nil
	Local oStPai       := FWFormStruct(1, 'SE1')
	// Local oStFilho     := FWFormStruct(1, 'SC6')
	// busca estrutura da view customsizada - cabeçalho
	// Local oStPai   := GetStruct("Model", "SC5", StrTokArr(SC5->(IndexKey(1)), "+") )
	// busca estrutura da view customizada - grid
	// Local oStFilho := GetStruct("Model", "SC6", StrTokArr(SC6->(IndexKey(1)), "+") )

	Local aSUBRel      := {}
	// bloco de load dos dados
	// Local bLoadCab  := {|oMdl| {""}}
	// Local bLoadGrid := {|oGridModel| loadGrid(oGridModel)}
	Local bCommit := {|oModel| CommitLib(oModel) }

	// remoção de campos
	// oStFilho:RemoveField("C6_ZSLDFAT")
	// oStFilho:RemoveField("C6_ZQTDENT")
	// oStFilho:RemoveField("C6_ZQTDEN2")
	// oStFilho:RemoveField("C6_ZSLDFA2")
	// oStFilho:RemoveField("C6_INFAD")
	// oStFilho:RemoveField("C6_CODINF")

	// gatilho no campo de quantidade liberada
	// oStFilho:AddTrigger("C6_QTDLIB", "C6_QTDLIB", {|| VldQtdLib(oModel) }, {|| GatQtdLib(oModel) })

	// Criando o modelo e os relacionamentos
	oModel := MPFormModel():New('KHRFCINM', /*bPreValidacao*/, /*bTudoOK*/, /*bCommit*/, /*bCancel*/)

	oModel:AddFields('SE1MASTER',/*cOwner*/,oStPai, /*bPre*/, /*bPost*/, )
	oModel:SetPrimaryKey({ 'E1_FILIAL', 'E1_NUM', 'E1_PREFIXO', 'E1_CLIENTE', 'E1_LOJA' })

	// oModel:AddGrid('SC6DETAIL','SE1MASTER',oStFilho,/*bLinePre*/, /*bPosVld*/ ,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence

	// Fazendo o relacionamento entre o Pai e Filho
	// aAdd(aSUBRel, {'C6_FILIAL','C5_FILIAL'})
	// aAdd(aSUBRel, {'C6_NUM',   'C5_NUM'})

	// Monta o relacionamento entre Grid e Cabeçalho, as expressões da Esquerda representam o campo da Grid e da direita do Cabeçalho
	// oModel:SetRelation('SC6DETAIL', aSUBRel, SC6->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado

	// Setando as descrições
	oModel:SetDescription("Títulos x Fast Connect")

Return oModel

/*/{Protheus.doc} ViewDef
    Visualização de dados
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 07/10/2021
    @return variant, return_description
    /*/
Static Function ViewDef()

	Local aAreaSX3	:= SX3->(GetArea())
	Local oView     := Nil
	Local oModel    := FWLoadModel('KHRFCINT')
	Local oStPai    := FWFormStruct(2, 'SE1')
	// Local oStFilho  := FWFormStruct(2, 'SC6')
	// busca estrutura da view customsizada - cabeçalho
	// Local oStPai   := GetStruct("View", "SC5")
	// busca estrutura da view customizada - grid
	// Local oStFilho := GetStruct("View", "SC6")

	// remoção de campos
	// oStFilho:RemoveField("C6_ZSLDFAT")
	// oStFilho:RemoveField("C6_ZQTDENT")
	// oStFilho:RemoveField("C6_ZQTDEN2")
	// oStFilho:RemoveField("C6_ZSLDFA2")
	// oStFilho:RemoveField("C6_INFAD")
	// oStFilho:RemoveField("C6_CODINF")

	//Criando a View
	oView := FWFormView():New()
	oView:SetModel(oModel)

	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_SE1',oStPai,'SE1MASTER')
	// oView:AddGrid('VIEW_SC6',oStFilho,'SC6DETAIL')

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',100)
	// oView:CreateHorizontalBox('GRID',50)

	// oView:CreateFolder( 'FOLDERCAB', 'CABEC')

	// oView:AddSheet('FOLDERCAB','GERAL','Dados - Orçamento')

	// oView:CreateHorizontalBox( 'GERALBOX', 100, /*owner*/, /*lUsePixel*/, 'FOLDERCAB', 'GERAL')
	// oView:CreateHorizontalBox( 'TOTALBOX', 100, /*owner*/, /*lUsePixel*/, 'FOLDERCAB', 'TOTAL')

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_SE1','CABEC')
	// oView:SetOwnerView('VIEW_SC6','GRID')

	// oView:SetNoInsertLine('VIEW_SC6')
	// oView:SetNoDeleteLine('VIEW_SC6')


	oView:EnableTitleView("VIEW_SE1", "Títulos x Fast Connect")
	// oView:EnableTitleView( 'VIEW_SC6', "Itens" )

	RestArea(aAreaSX3)

Return oView

/*/{Protheus.doc} z1325Leg
    Legenda
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 09/08/2021
    @return variant, return_description
    /*/
User Function FCIntLeg()

	Local aLegenda := {}
	Local cTitulo  := "Legenda Fast Connect"

	// Monta as cores
	aAdd(aLegenda, {"GCTPIMST.PNG",  "Aguardando envio à Fast Connect"})
	// aAdd(aLegenda, {"ATALHO.PNG",    "Título enviado à Fast Connect"})
	aAdd(aLegenda, {"DESTINOS.PNG",  "Título recebido pela Fast Connect"})
	aAdd(aLegenda, {"DBG09.PNG",     "Erro no envio do título à Fast Connect"})
	aAdd(aLegenda, {"CANCEL.PNG",    "Título cancelamento na Fast Connect"})
	aAdd(aLegenda, {"RECORRENTE.PNG","Reenvio do título à Fast Connect"})
	// aAdd(aLegenda, {"BTCALEND.PNG",	 "Alteração de vencimento. Aguardando envio para a Fast Connect"})
	aAdd(aLegenda, {"ALTERA.PNG",	 "Alteração de dados. Aguardando envio para a Fast Connect"})
	aAdd(aLegenda, {"BR_VERMELHO",	 "Título integrado e baixado com sucesso"})

	// exibe tela de legendas
	BrwLegenda(cTitulo, "Status", aLegenda)

Return
