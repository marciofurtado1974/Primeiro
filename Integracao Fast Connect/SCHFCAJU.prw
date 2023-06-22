#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} SCHFCAJU
    Schedule para ajuste de dados de gistro da FastConnect
        Por vezes não são recebidos os dados corretamente, necessitanto consultá-los pela api e ajusta-los
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 27/02/2023
    /*/
User Function SCHFCAJU(aParams)

    Local _cLockFile 	:= ""
    // Local _nHdlJob   := 0
	Local lJob		 	:= IsBlind()
	// verifica se é base teste ou produção para alterar endpoints
    Local lBaseProducao := Upper(AllTrim(GetSrvProfString("dbalias", ""))) == "SIGAPROD"
    Local nX
	Local cQuery := ""
	Local oRest								as object
	Local aHeader := {}

	Default aParams 	:= {"04", "01"}
	
	Private HOST 		:= ""
	Private TOKEN		:= ""
	Private CLIENT_CODE := ""

	If lJob
		// prepara ambiente
		RpcSetType(3)
		RpcSetEnv(aParams[1], aParams[2],,,,,,,,,)
	EndIf

	If lBaseProducao
		HOST		:= "https://api.fpay.me"
	Else
		HOST		:= "https://api-sandbox.fpay.me"
	EndIf
	TOKEN		:= SuperGetMV("MV_TOKENFC", .F., "")
	CLIENT_CODE := SuperGetMV("MV_CLICOFC", .F., "")

    // Montagem do arquivo do job principal
	_cLockFile := Lower("SCHFCAJU" + cEmpAnt + cFilAnt)// + ".lck"
    
	// cabeçalho de requisição
	aAdd(aHeader, "Content-Type: application/json")
	aAdd(aHeader, "Client-Code: " + CLIENT_CODE)
	aAdd(aHeader, "Client-key: " + TOKEN)
	
    // verifica se o JOB esta em execucao
	If GlbNmLock(_cLockFile)

        DbSelectArea("Z03")
        DbSelectArea("Z04")

        // endereço da integração
        oRest  := FWRest():New(HOST)

        // busca os títulos integrados (não baixados nem cancelados) na fast sem dados de linha digitável ou link de pdf
        cQuery := " SELECT Z04.r_e_c_n_o_ as Z04
        cQuery += " FROM " + RetSQLTab("Z04") 
        cQuery += "         INNER JOIN " + RetSQLTab("SE1") 
        cQuery += "         ON " + RetSQLCond("SE1") 
        cQuery += "         AND E1_NUM     = Z04_TITULO 
        cQuery += "         AND E1_PREFIXO = Z04_PREFIX 
        cQuery += "         AND E1_PARCELA = Z04_PARCEL
        cQuery += "         AND E1_CLIENTE = Z04_CLIENT
        cQuery += "         AND E1_LOJA    = Z04_LOJA
        cQuery += "         AND E1_ZSTATFC = 'R'
        cQuery += "         AND E1_SALDO > 0
        cQuery += " WHERE Z04.D_E_L_E_T_ = ' ' 
        cQuery += " AND Z04.Z04_STATUS = 'T'
        cQuery += " AND Z04.Z04_CANCEL = 'F'
        cQuery += " AND (Z04.Z04_LINDGT = ' ' OR Z04.Z04_PDF = ' ')

        aRetZ04 := U_SqlToVet(cQuery)
        
        DbSelectArea("Z03")
        For nX := 1 To Len(aRetZ04)
            Z04->(DbGoTo(aRetZ04[nX, 1]))

            // path + parâmetro
            oRest:SetPath("/boleto/" + AllTrim(Z04->Z04_IDFAST))

            // json com os dados de envio
            oRest:SetChkStatus(.T.)

            // tenta efetuar o Post
            If oRest:Get(aHeader)

                // Resgata a resposta do JSON
                jJson    := JsonObject():New()
                jJson:FromJson(DecodeUTF8(oRest:GetResult()))

                // status cancelado
                If Upper(Alltrim(jJson["data"]["situacao"])) == "CANCELADO"
                    Loop
                EndIf
            EndIf

            // grava dados
            If jJson:HasProperty("linha_digitavel") .and. jJson:HasProperty("linha_digitavel") ;
                .and. !Empty(jJson["linha_digitavel"]) .and. !Empty(jJson["link_pdf"])

                RecLock("Z04", .F.)
                    Z04->Z04_LINDGT := jJson["linha_digitavel"]
                    Z04->Z04_PDF 	:= jJson["link_pdf"]
                MsUnlock()
            EndIf
            If jJson:HasProperty("data") .and. !Empty(jJson["data"]["linha_digitavel"]) .and. !Empty(jJson["data"]["link_pdf"])
                RecLock("Z04", .F.)
                    Z04->Z04_LINDGT := jJson["data"]["linha_digitavel"]
                    Z04->Z04_PDF 	:= jJson["data"]["link_pdf"]
                MsUnlock()
            EndIf

        Next Nx

        GlbNmUnlock(_cLockFile)

	Else
		Conout("[SCHFCONN] - Não conseguiu lock.")
	EndIf

	If lJob
		RpcClearEnv()
	EndIf
	
Return Nil
