#Include "Protheus.ch"
#Include "Colors.ch"
#Include "RptDef.ch"
#Include "FwPrintSetup.ch" 

/*/{Protheus.doc} FCRELABX
    Relatório de baixas dos repasses enviados pela Fast Connect
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 18/07/2022
    @return Nil
    /*/
User Function FCRELABX()

    Local oReport
	
	// Private cAliasTmp  := Getnextalias()

	// valida se possui integração com a Fast Connect
	If GetNewPar("FC_ATIVO", .F.)

		oReport := ReportDef()
		If !Empty(oReport)
			oReport:PrintDialog()
		EndIf

	Else
		FwAlertWarning("Empresa não possui integração com a Fast Connect")
	EndIf

	// If(Select(cAliasTmp) <> 0, (cAliasTmp)->(DbCloseArea()), Nil)

Return Nil


/*/{Protheus.doc} ReportDef
    Estrutura do relatório
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 20/12/2021
    @return variant, return_description
    /*/
Static Function ReportDef()

	Local oReport
	Local cPerg      := "FCRELABX"
    Local cNomeRel   := "Repasses Fast Conenct"
    Local lBreakLine := .T.

	oReport := TReport():New("FCRELABX",cNomeRel,/*Pergunte*/, {|oReport| ReportPrint(oReport)},cNomeRel)
	oReport:SetLandscape(.F.)   // Define a orientação de página do relatório como paisagem  ou retrato. .F.=Retrato; .T.=Paisagem
	oReport:SetTotalInLine(.F.) // Define se os totalizadores serão impressos em linha ou coluna

	If !Pergunte(cPerg,.T.)
		Return Nil
	EndIf

	oSection := TRSection():New(oReport,cNomeRel,/*{Tabelas da secao}*/,/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	// oSection:SetTotalInLine(.F.)  // Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha
	//TRCEll():New( oParent   , cName     , cAlias    , cTitle     , cPicture , nSize     , lPixel   ,{|| bBlock }, cAlign , lLineBreak , cHeaderAlign , ; lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
	TRCell():New(oSection,"TITULO"	    ,"Z08", "Título",    		""                  ,07						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"PREFIXO"	    ,"Z08", "Prefixo",    	    ""                  ,03						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"PARCELA"	    ,"Z08", "Parcela",  		""                  ,03						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"CLIENTE"	    ,"Z08", "Cliente",  		""                  ,50                     ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"TIPO"	    ,"Z08", "Tipo",     		""                  ,07                     ,/*lPixel*/,/*{|| code-block de impressao }*/,,lBreakLine)
	TRCell():New(oSection,"STATUS"	    ,"Z08", "Status",    	    ""                  ,10                     ,/*lPixel*/,/*{|| code-block de impressao }*/,,lBreakLine)
	TRCell():New(oSection,"MENSAGEM"	,"Z08", "Mensagem",         ""                  ,30    				    ,/*lPixel*/,/*{|| code-block de impressao }*/,,lBreakLine)
	TRCell():New(oSection,"NUMFST"	    ,"SE1", "Num. Fast",    	""				    ,TamSX3("E1_ZNUMFST")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"VALORTIT"	,"SE1", "Vlr. Título",    	"@E R$ 999 999.99"	,15						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"DATA"	    ,"Z08", "Dt Repasse",  	    "@D"                ,TamSX3("Z08_DTREPA")[1],/*lPixel*/,/*{|| code-block de impressao }*/)
	// TRCell():New(oSection,"HORA"	    ,"Z08", "Hr Repasse",       ""                  ,TamSX3("Z08_HORA")[1]  ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"VALORREP"	,"Z08", "Vlr. Repasse",     "@E R$ 999 999.99"	,15						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"JUROS"	    ,"Z08", "Vlr. Juros",    	"@E R$ 999 999.99"	,15						,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection,"MULTA"	    ,"Z08", "Vlr. Multa",    	"@E R$ 999 999.99"	,15						,/*lPixel*/,/*{|| code-block de impressao }*/)


	oSection:SetTotalInLine(.F.)    // Imprime total em linha
	oSection:SetHeaderSection(.T.)  // Define que imprime cabeçalho das células na quebra de seção
	// oSection:SetLeftMargin(5)       // Margem impressão

    // total por data
	oBreakData := TRBreak():New(oSection,oSection:Cell("DATA"), "Total: ",.F.)
	TRFunction():New(oSection:Cell("NUMFST")  ,,"COUNT",oBreakData ,"Qtd Baixas",, {|| If(Z08->Z08_STATUS == "B", .T., .F.) },.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("VALORTIT"),,"SUM",oBreakData ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("VALORREP"),,"SUM",oBreakData ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("JUROS")   ,,"SUM",oBreakData ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("MULTA")   ,,"SUM",oBreakData ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
    // total geral
	oBreakGeral := TRBreak():New(oSection,{||  }, "Total Geral: ",.F.)
	TRFunction():New(oSection:Cell("NUMFST")  ,,"COUNT",oBreakGeral ,"Qtd Baixas",, {|| If(Z08->Z08_STATUS == "B", .T., .F.) },.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("VALORTIT"),,"SUM",oBreakGeral ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("VALORREP"),,"SUM",oBreakGeral ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("JUROS")   ,,"SUM",oBreakGeral ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )
	TRFunction():New(oSection:Cell("MULTA")   ,,"SUM",oBreakGeral ,,,/*uFormua*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/ )

Return(oReport)

/*/{Protheus.doc} ReportPrint
	Dados do relatório
	@type function
	@version 1.0
	@author Daniel Scheeren - Gruppe
	@since 14/12/2021
	@param oReport, object, Objeto TReport
	@return variant, return_description
	/*/
Static Function ReportPrint(oReport)

	Local oSection1  := oReport:Section(1)
	Local _cQuery    := ""
    Local cStatus    := ""
    Local cTipoTit   := ""
	Local aCombo     := RetSX3Box(GetSX3Cache("Z08_STATUS", "X3_CBOX"),,,1)	// verifica se é base teste ou produção para alterar endpoints
    Local lBaseProducao := Upper(AllTrim(GetSrvProfString("dbalias", ""))) == "SIGAPROD"
	Local cHost 		:= ""
	Local cPath 		:= "/venda/recebidos?data_conciliacao="
	Local aHeader 		:= {}
	Local cClientCode   := SuperGetMV("MV_CLICOFC", .F., "")
	Local cToken		:= SuperGetMV("MV_TOKENFC", .F., "")
	// diferença em dias das datas do parâmetroe
	Local nDiasDiff		:= DateDiffDay(MV_PAR01, MV_PAR02) + 1
	Local cDataPesq  	:= ""
	Local nX
	Local aDadosFst		:= {}

	If lBaseProducao
		cHost		:= "https://api.fpay.me"
	Else
		cHost		:= "https://api-sandbox.fpay.me"
		cToken  	:= "6ea297bc5e294666f6738e1d48fa63d2"
		cCliToken   := "FC-SB-15"
	EndIf

	// cabeçalho de requisição
	aAdd(aHeader, "Content-Type: application/json")
	aAdd(aHeader, "Client-Code: " + cClientCode)
	aAdd(aHeader, "Client-key: " + cToken)


	  // _cQuery := " SELECT "
	// _cQuery += "      Z08_TITULO "
	// _cQuery += "     ,Z08_PREFIX "
	// _cQuery += "     ,Z08_PARCEL "
	// _cQuery += "     ,Z08_CLIENT "
	// _cQuery += "     ,Z08_LOJA "
	// _cQuery += "     ,A1_NOME "
	// _cQuery += "     ,Z08_TIPTIT "
	// // _cQuery += "     Z08_HORA, "
	// _cQuery += "     ,Z08_STATUS "
	// _cQuery += "     ,Z08_MENSAG "
	// _cQuery += "     ,E1_ZNUMFST "
    // // KME
	// If cEmpAnt == "06"
	// 	_cQuery += "    ,SE1.E1_VALOR + SE1.E1_ACRESC - SE1.E1_DECRESC - (SE1.E1_ISS + SE1.E1_CSLL + SE1.E1_COFINS + SE1.E1_INSS + SE1.E1_PIS + SE1.E1_IRRF) AS TOTAL "
	// Else
	// 	_cQuery += "    ,(CASE WHEN ED_CALCISS = 'S' THEN (SE1.E1_VALOR + SE1.E1_ACRESC - SE1.E1_DECRESC - SE1.E1_ISS) ELSE (SE1.E1_VALOR + SE1.E1_ACRESC - SE1.E1_DECRESC) END) AS TOTAL "
	// EndIf
	// _cQuery += "     ,Z08_DTREPA "
	// _cQuery += "     ,Z08_VLREPA "
	// _cQuery += "     ,Z08_VLRJUR "
	// _cQuery += "     ,Z08_VLRMUL "
	// _cQuery += " FROM "
	// _cQuery += "     " + RetSQLTab("Z08")
	// _cQuery += "     INNER JOIN " + RetSQLTab("SE1")
    // _cQUery += "            ON " + RetSQLCond("SE1")
	// _cQuery += "            AND E1_NUM = Z08_TITULO "
	// _cQuery += "            AND E1_PREFIXO = Z08_PREFIX "
	// _cQuery += "            AND E1_PARCELA = Z08_PARCEL "
	// _cQuery += "            AND E1_CLIENTE = Z08_CLIENT "
	// _cQuery += "            AND E1_LOJA = Z08_LOJA "
    // // remove do filtro registros de impostos
	// _cQuery += "            AND SUBSTR(E1_TIPO, 3, 1) <> '-' "
	// _cQuery += "     INNER JOIN " + RetSQLTab("SA1")
    // _cQUery += "            ON " + RetSQLCond("SA1")
	// _cQuery += "            AND A1_COD = E1_CLIENTE "
	// _cQuery += "            AND A1_LOJA = E1_LOJA "
	// _cQuery += "     INNER JOIN " + RetSQLTab("SED")
    // _cQUery += "            ON " + RetSQLCond("SED")
	// _cQuery += "            AND ED_CODIGO = E1_NATUREZ "
    // _cQuery += " WHERE "
    // _cQuery += "     " + RetSQLCond("Z08")
    // _cQuery += "     AND Z08_DTREPA BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02)+ "' "
    // // status baixa
    // If MV_PAR03 != 1  // todos
    //     _cQuery += "     AND Z08_STATUS = '" + aCombo[MV_PAR03, 2] + "' "
    // EndIf
    // _cQuery += " ORDER BY Z08_DTREPA, Z08_TITULO, Z08_PREFIX, Z08_PARCEL, Z08_CLIENT, Z08_LOJA, Z08_HORA "

	// If Select(cAliasTmp) <> 0
	// 	(cAliasTmp)->(dbCloseArea())
	// EndIf

	// _cQuery    := ChangeQuery(_cQuery)
	// DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),cAliasTmp,.F.,.T.)
    // Count to nCount
    // (cAliasTmp)->(DbGoTop())
    
    // oReport:SetMeter(nCount)
	// While (cAliasTmp)->(!Eof())


        // // incrementa régua de progressão
	    // oReport:IncMeter()

        // // status da baixa
        // Do Case
        //     Case (cAliasTmp)->Z08_STATUS == "P"
        //         cStatus := "Pendente de baixa"
        //     Case (cAliasTmp)->Z08_STATUS == "B"
        //         cStatus := "Baixado"
        //     Case (cAliasTmp)->Z08_STATUS == "D"
        //         cStatus := "Repasse em duplicidade"
        //     Case (cAliasTmp)->Z08_STATUS == "E"
        //         cStatus := "Erro na baixa"
        //     Case (cAliasTmp)->Z08_STATUS == "F"
        //         cStatus := "Falha no processo"
        //     Otherwise
        //         cStatus := "Status não identificado"
        // EndCase

        // // tipo de integração
        // Do Case
        //     Case (cAliasTmp)->Z08_TIPTIT == "BOL"
        //         cTipoTit := "Boleto"
        //     Case (cAliasTmp)->Z08_TIPTIT == "CC"
        //         cTipoTit := "C. Crédito"
        //     Otherwise
        //         cTipoTit := "Tipo de título inválido"
        // EndCase

		// // Início da seção
		// oSection1:Init()

		// oSection1:Cell("TITULO"  ):SetValue((cAliasTmp)->Z08_TITULO)
		// oSection1:Cell("PREFIXO" ):SetValue((cAliasTmp)->Z08_PREFIX)
		// oSection1:Cell("PARCELA" ):SetValue((cAliasTmp)->Z08_PARCEL)
		// oSection1:Cell("CLIENTE" ):SetValue((cAliasTmp)->(Z08_CLIENT + "/" + Z08_LOJA + " - " + A1_NOME))
        // oSection1:Cell("TIPO"    ):SetValue(cTipoTit)           // BOL=Boleto;CC=C. Crédito
		// oSection1:Cell("STATUS"  ):SetValue(cStatus)            // P=Pendente Baixa;B=Baixado;E=Erro;D=Duplicado
		// oSection1:Cell("MENSAGEM"):SetValue((cAliasTmp)->Z08_MENSAG)
		// oSection1:Cell("NUMFST"  ):SetValue((cAliasTmp)->E1_ZNUMFST)
		// oSection1:Cell("VALORTIT"):SetValue((cAliasTmp)->TOTAL)
		// oSection1:Cell("DATA"    ):SetValue(SToD((cAliasTmp)->Z08_DTREPA))
		// oSection1:Cell("VALORREP"):SetValue((cAliasTmp)->Z08_VLREPA)
		// oSection1:Cell("JUROS"   ):SetValue((cAliasTmp)->Z08_VLRJUR)
		// oSection1:Cell("MULTA"   ):SetValue((cAliasTmp)->Z08_VLRMUL)
		// // oSection1:Cell("HORA"    ):SetValue((cAliasTmp)->Z08_HORA)

		// oSection1:PrintLine()
	
	// 	(cAliasTmp)->(DbSkip())
	// End

	

	For nX := 0 To nDiasDiff-1

		// formata parametro de data
		cDataPesq := Transform(DToS(DaySum(MV_PAR01, nX)), "@R 9999-99-99")
	
		// endereço da integração
		oRest	:= FWRest():New(cHost)

		// path + parâmetro
		oRest:SetPath(cPath + cDataPesq)

		// json com os dados de envio
		oRest:SetChkStatus(.T.)

		// verifica se o título já foi cadastrado na Fast para efetuar o delete
		If oRest:Get(aHeader)

			jJson    := JsonObject():New()
			// resgata a resposta do JSON
			jJson:FromJson(DecodeUTF8(oRest:GetResult()))
			
			If jJson:HasProperty("data") .and. !Empty(jJson["data"])

	
				// DbSelectArea("Z04")
				// DbSetOrder(1)
				// DbSelectArea("Z05")
				// DbSetOrder(1)
				DbSelectArea("Z08")
				DbSetOrder(1)

				For nX := 1 To Len(jJson["data"])

					jRepasse  := jJson["data"][nX]
					cChaveRef := ""
					cTabInteg := ""
					aRet 	  := {}

					If AllTrim(jRepasse['tipo']) == "boleto"
						cTabInteg := "Z04"
					Else
						cTabInteg := "Z05"
					EndIf

					// incrementa régua de progressão
					oReport:IncMeter()

					// busca na tabela de integração o título
					// If jRepasse:HasProperty("fid") .and. (cTabInteg)->(DbSeek(FWxFilial(cTabInteg, cFilial) + AllTrim(jRepasse['fid'])))
					If jRepasse:HasProperty("fid")

						cQuery := " SELECT " + cTabInteg + "_CODREF "
						cQuery += " FROM " + RetSQLTab(cTabInteg)
						cQuery += " WHERE " + RetSQLCond(cTabInteg)
						cQuery += " AND " + cTabInteg + "_IDFAST = '" + AllTrim(jRepasse['fid']) + "' "

						aRet := U_SQLToVet(cQuery)
						
						If !Empty(aRet)
							// chave de referência contendo os dados da empresa e titulo
							cChaveRef := AllTrim(aRet[1, 1])
						EndIf
					
					// se por algum motivo não encontrar na tabela de integração, busca o numero de referencia na Fast
					Else
						// valida se recebeu o código identificador do título
						If jRepasse:HasProperty("nu_referencia")

							// chave de referência contendo os dados da empresa e titulo
							cChaveRef := AllTrim(SubStr(jRepasse["nu_referencia"], 1, At(".", jRepasse["nu_referencia"])-1))   // remove o ".0" ao final que se trata de um contador da venda via link, pois a Fast permite mais de uma venda por link

						// valida se recebeu o código identificador da venda
						ElseIf jRepasse:HasProperty("fid")

							// endereço da integração
							oRestVenda := FWRest():New(cHost)

							// path consutla credito
							oRestVenda:SetPath("/" + jRepasse['tipo'] + "/" + AllTrim(jRepasse['fid']))

							oRestVenda:SetChkStatus(.T.)

							// tenta efetuar o Get
							If oRestVenda:Get(aHeader)

								jJsonRet := JsonObject():New()

								// resgata a resposta do JSON
								jJsonRet:FromJson(DecodeUTF8(oRestVenda:GetResult()))

								jJsonRet := jJsonRet['data']

								// chave de referência contendo os dados da empresa e titulo
								cChaveRef := If(jJsonRet:HasProperty('nu_referencia'), AllTrim(jJsonRet["nu_referencia"]), "")   // remove o ".0" ao final que se trata de um contador da venda via link, pois a Fast permite mais de uma venda por link
								
							Else
								lRet                 := .F.
								cCodErro             := 400 // Bad Request
								jResponse["message"] := "Não foi possível encontrar a venda. - " + AllTrim(jRepasse['fid'])
							EndIf

						Else
							cChave  := ""
							cStatus := "Repasse sem numero de referência. Entrar em contato com a Fast Connect."
						EndIf
					EndIf

					// dados da empresa
					cEmpresa := SubStr(cChaveRef, 1, Len(FwCodEmp()))
					cFilial  := SubStr(cChaveRef, Len(FwCodEmp())+1, Len(FwCodFil()))
					
					// atualiza chave, removendo dados da empresa
					cChave    := SubStr(cChaveRef, (Len(FwCodEmp()) + Len(FwCodFil()) + 1))

					// separa os dados do título
					nPos        := 1
					// Num Título
					cNumTitulo  := SubStr(cChave, nPos, TamSX3("E1_NUM")[1])
					nPos       	+= Len(cNumTitulo)
					// Prefixo
					cPrefixo 	:= SubStr(cChave, nPos, TamSX3("E1_PREFIXO")[1])
					nPos        += Len(cPrefixo)
					// Parcela
					cParcela 	:= SubStr(cChave, nPos, TamSX3("E1_PARCELA")[1])
					nPos        += Len(cParcela)
					// Cliente
					cCliente 	:= SubStr(cChave, nPos, TamSX3("E1_CLIENTE")[1])
					nPos        += Len(cCliente)
					// Loja
					cLoja 		:= SubStr(cChave, nPos, TamSX3("E1_LOJA")[1])
					nPos        += Len(cLoja)
					// Tipo
					cTipoTitulo := SubStr(cChave, nPos, TamSX3("E1_TIPO")[1])
					nPos        += Len(cTipoTitulo)

					If Z08->(DbSeek(FWxFilial("Z08", cFilial) + cNumTitulo + cPrefixo + cParcela + cCliente + cLoja))
						
						// status da baixa
						Do Case
							Case Z08->Z08_STATUS == "P"
								cStatus := "Pendente de baixa"
							Case Z08->Z08_STATUS == "B"
								cStatus := "Baixado"
							Case Z08->Z08_STATUS == "D"
								cStatus := "Repasse em duplicidade"
							Case Z08->Z08_STATUS == "E"
								cStatus := "Erro na baixa"
							Case Z08->Z08_STATUS == "F"
								cStatus := "Falha no processo"
							Otherwise
								cStatus := "Status não identificado"
						EndCase

						// tipo de integração
						Do Case
							Case AllTrim(Z08->Z08_TIPTIT) == "BOL"
								cTipoTit := "Boleto"
							Case AllTrim(Z08->Z08_TIPTIT) == "CC"
								cTipoTit := "C. Crédito"
							Otherwise
								cTipoTit := "Tipo de título inválido"
						EndCase

					Else
						cTipoTit := ""
						cStatus  := "Repasse não gravado. Executar reenvio de repasses para ajuste."
					EndIf


					// Início da seção
					oSection1:Init()

					oSection1:Cell("TITULO"  ):SetValue(Z08->Z08_TITULO)
					oSection1:Cell("PREFIXO" ):SetValue(Z08->Z08_PREFIX)
					oSection1:Cell("PARCELA" ):SetValue(Z08->Z08_PARCEL)
					oSection1:Cell("CLIENTE" ):SetValue(Z08->(Z08_CLIENT + "/" + Z08_LOJA) + " - " + Posicione("SA1", 1, FWxFilial("SA1") + cCliente + cLoja, "A1_NOME"))
					oSection1:Cell("TIPO"    ):SetValue(cTipoTit)           // BOL=Boleto;CC=C. Crédito
					oSection1:Cell("STATUS"  ):SetValue(cStatus)            // P=Pendente Baixa;B=Baixado;E=Erro;D=Duplicado
					oSection1:Cell("MENSAGEM"):SetValue(Z08->Z08_MENSAG)
					oSection1:Cell("NUMFST"  ):SetValue(SubStr(jRepasse['nu_venda'], 1, 6))
					oSection1:Cell("VALORTIT"):SetValue(If(jRepasse:HasProperty('vl_venda'), Val(jRepasse['vl_venda']), 0))
					oSection1:Cell("DATA"    ):SetValue(SToD(SubStr(StrTran(jRepasse['dt_recebimento'], "-", ""), 1, 8)))
					oSection1:Cell("VALORREP"):SetValue(Z08->Z08_VLREPA)
					oSection1:Cell("JUROS"   ):SetValue(Z08->Z08_VLRJUR)
					oSection1:Cell("MULTA"   ):SetValue(Z08->Z08_VLRMUL)
					// oSection1:Cell("HORA"    ):SetValue(Z08->Z08_HORA)

					oSection1:PrintLine()
				
				Next

			EndIf

		EndIf
	Next

	oSection1:Finish()

Return
