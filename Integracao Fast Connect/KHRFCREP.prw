#Include "Protheus.ch"

#Define enter Chr(13) + Chr(10)

/*/{Protheus.doc} KHRFCREP
    Solicita��o de reenvio de repasses para Fast Connect
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
@since 09/02/2023
    @return variant, return_description
    /*/
User Function KHRFCREP()
    
	Local oWindow, oPanel, oGet1
    Local dData := SToD("")
	// valida se o banco foi informado para baixa ou se o motivo de baixa n�o realiza movimento banc�rio, permite confirmar sem banco 
	Local bValidaOK := {|| If(!Empty(dData) .and. dData <= Date(), oWindow:DeActivate(), FwAlertError("Necess�rio informar uma data v�lida!")) }

	Private lRet 	    := .T.
    Private cMsgRet := ""

	// see��o do banco para gravar a baixa
	oWindow := FWDialogModal():New()
	oWindow:SetBackground(.T.)
	oWindow:SetTitle("Reenvio de repasses da Fast Connect.")
	oWindow:SetSubTitle("Selecione uma data para realizar o reenvio de repasses.")
	//Seta a largura e altura da janela em pixel
	oWindow:SetSize(150, 200)
	oWindow:EnableFormBar(.T.)
	oWindow:SetCloseButton(.F.)
	oWindow:SetEscClose(.F.)
	oWindow:CreateDialog()
	oWindow:AddCloseButton(bValidaOK, "Confirmar")
	oWindow:AddButtons({{, "Cancelar", {|| lRet := .F., oWindow:DeActivate() }, "Cancelar", , .T., .F.}})

	oPanel := oWindow:GetPanelMain()

	TSay():New(005,005,{|| "Data: "}, oPanel,,,,,,.T.,,,30,20,,,,,,.T.)
	oGet1 := TGet():New(015,005,{|u| If(PCount()>0,dData:=u,dData) },oPanel,050,010,'',{||  },CLR_BLACK,CLR_WHITE,,,,.T.,,,{|| },,,{||  },.F.,.F.,,"dData",,,,.F.,.F.,,"", 2,,,,,)
	
	oWindow:Activate()

    If lRet
        FwMsgRun(Nil, {|oSay| lRet := ExecRepasses(dData)}, "Aguarde...", "Solicitando repasses...")

        If lRet
            FwAlertSuccess('<span style="color:red">Os repasses podem demorar conforme a quantidade e processamento da Fast Connect!' + enter +;
                " Ap�s o repasse recebido o sistema far� a baixa dos t�tulos automaticamente (executado de hora em hora)!</span>",;
                "Repasse solicitado com sucesso.")
        Else
            FwAlertError("Retorno da Fast Connect: " + enter + cMsgRet, "Ocorreu um erro na solicita��o do repasse!")
        EndIf
    EndIf

Return Nil

/*/{Protheus.doc} ExecRepasses
    Envia requisi�a� de repasse
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 2/9/2023
    @param dData, date, Data do repasse que ser� solicitado
    @return variant, return_description
    /*/
Static Function ExecRepasses(dData)

    Local lBaseProducao := Upper(AllTrim(GetSrvProfString("dbalias", ""))) == "SIGAPROD"
	Local cHost 		:= ""
	Local cPath 		:= "/webhook/recebidos"
	Local aHeader 		:= {}
	Local cClientCode   := SuperGetMV("MV_CLICOFC", .F., "")
	Local cToken		:= SuperGetMV("MV_TOKENFC", .F., "")
    Local jJson         := JsonObject():New()

	If lBaseProducao
		cHost			:= "https://api.fpay.me"
	Else
		cHost			:= "https://api-sandbox.fpay.me"
	EndIf

    jJson["data_conciliacao"] := Transform(DToS(dData), "@R 9999-99-99")

	// cabe�alho de requisi��o
	aAdd(aHeader, "Content-Type: application/json")
	aAdd(aHeader, "Client-Code: " + cClientCode)
	aAdd(aHeader, "Client-key: " + cToken)

    // endere�o da integra��o
    oRest	:= FWRest():New(cHost)

    // path + par�metro
    oRest:SetPath(cPath)

    // json com os dados de envio
    oRest:SetChkStatus(.T.)

    // verifica se o t�tulo j� foi cadastrado na Fast para efetuar o delete
    If oRest:Post(aHeader, jJson:ToJson())

        lRet  := .T.

    Else
        jJson := JsonObject():New()
        // resgata a resposta do JSON
        jJson:FromJson(DecodeUTF8(oRest:GetResult()))

        If jJson:HasProperty("data")
            cMsgRet := jJson:GetJsonText("data")
        EndIf

    EndIf
    
Return lRet
