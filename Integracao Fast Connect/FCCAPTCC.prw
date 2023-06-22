#include "Protheus.ch"

#define enter Chr(13)+Chr(10)

/*/{Protheus.doc} FCCAPTCC
    Integra��o FastConnect para captura de status de cart�o de cr�dito
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 3/13/2023
    @return variant, return_description
    /*/
User Function FCCAPTCC(lReenvia)
    
    Local aArea         := GetArea()
	Local aHeader		:= {}				as array
	Local lRet  		:= .T. 				as logical
	Local oRest								as object
	Local jJsonRet							as json
	Local jJsonEnvio						as json
	Local jJsonData							as json
	// Local cDataVncto	:= ""				as character
	Local aDadosLog		:= {"","","","","",""} as array
	// Local cJson 		:= ""				as character
	Local cChave		:= ""				as character
	// verifica se � base teste ou produ��o para alterar endpoints
    Local lBaseProducao := Upper(AllTrim(GetSrvProfString("dbalias", ""))) == "SIGAPROD"
    Local cHost         := ""
    Local cURLRetorno   := ""
    Local cToken        := SuperGetMV("MV_TOKENFC", .F., "")
    Local cCliToken     := SuperGetMV("MV_CLICOFC", .F., "")
    Local cPathCaptura  := "/link/validacao"
    Local lConfirma     := .T.
    Local cEmailCad     := SuperGetMV("FC_MAILCAD", .F., "cadastro1@grupokhronos.com.br")
    Local cEmailCpy     := "daniel.scheeren@gruppe.com.br"

    // indica que deve reenviar a captura de cart�o
    Default lReenvia := .F.

	If lBaseProducao
        cHost       := "https://api.fpay.me"
		// url de retorno base produ��o
		cURLRetorno := SuperGetMV("FC_WSRETCA", .F., "http://erp.grupokhronos.com.br:9090/rest/notifica/captura")
	Else
        cHost       := "https://api-sandbox.fpay.me"
        cToken      := "6ea297bc5e294666f6738e1d48fa63d2"
        cCliToken   := "FC-SB-15"
		// url de retorno base teste
		cURLRetorno := "http://erp.grupokhronos.com.br:9093/rest/notifica/captura"
	EndIf

    // limpa campo de status para reenvio
    If lReenvia
        lConfirma := .F.

        // link j� enviado
        If !Empty(SZC->ZC_STATUSC) .and. FwAlertYesNo("Deseja realmente enviar uma nova captura de cart�o de cr�dito ao cliente?", "Captura de cart�o de cr�dito")
            lConfirma := .T.

        // cliente ainda n�o possui captura de cart�o
        ElseIf Empty(SZC->ZC_STATUSC) .and. FwAlertYesNo("Cliente n�o possui capura de cart�o de cr�dito pendente. Deseja enviar a captura?", "Captura de cart�o de cr�dito")
            lConfirma := .T.
        EndIf

        If lConfirma
            RecLock("SZC", .F.)
                SZC->ZC_STATUSC := ""
            SZC->(MsUnlock())
        Else
            Return Nil
        EndIf
    EndIf

    // cabe�alho de requisi��o
    aAdd(aHeader, "Content-Type: application/json")
    aAdd(aHeader, "Client-Code: " + cCliToken)
    aAdd(aHeader, "Client-key: " + cToken)

    If GetNewPar("FC_ATIVO", .F.)
        
        // s� realiza captura do cart�o se n�o enviado ou com erro
        If AllTrim(SZC->ZC_FORMA) == "CC" .and. SZC->(FieldPos("ZC_STATUSC")) > 0 .and. Empty(SZC->ZC_STATUSC)

            DbSelectArea("SA1")
            SA1->(dbSetOrder(1))//A1_FILIAL+A1_COD+A1_LOJA
            If SA1->(dbSeek(xFilial("SA1") + SZC->ZC_CLIENTE + SZC->ZC_LOJA))

                // dados do t�tulo para grava��o do log
                aDadosLog := {;
                    SZC->ZC_NUM,;
                    SA1->A1_COD,;
                    SA1->A1_LOJA,;
                    "",;
                    "",;
                    "",;
                    "";
                }

                // formata data de vencimento
                // cDataVncto := SubStr((_cAliasTmp)->VENCTO, 1, 4) + "-" + SubStr((_cAliasTmp)->VENCTO, 5, 2) + "-" + SubStr((_cAliasTmp)->VENCTO, 7, 2)

                // chave de referencia
                cChave := FwCodEmp() + FwCodFil() + SZC->ZC_NUM + SA1->A1_COD + SA1->A1_LOJA

                // verifica se possui mais de um e-mail para enviar somente o primeiro
                nMultEmail := At(";", AllTrim(SA1->A1_EMAIL)) -1
                // separa os demais e-mail para enviar como c�pia
                cEmailCC := If(nMultEmail > 0, AllTrim(SubStr(SA1->A1_EMAIL, At(";", AllTrim(SA1->A1_EMAIL)))), "")
                
                // JSON
                jJsonEnvio  := JsonObject():New()
                jJsonEnvio['nu_referencia'] 	    := cChave
                jJsonEnvio['nu_documento'] 		    := AllTrim(SA1->A1_CGC)
                jJsonEnvio['url_retorno'] 		    := cURLRetorno
                jJsonEnvio['ds_cep'] 			    := AllTrim(SA1->A1_CEP)
                jJsonEnvio['ds_endereco'] 		    := EncodeUtf8(AllTrim(SA1->A1_END))
                jJsonEnvio['ds_bairro'] 		    := EncodeUtf8(AllTrim(SA1->A1_BAIRRO))
                jJsonEnvio['ds_complemento'] 	    := EncodeUtf8(AllTrim(SA1->A1_COMPLE))
                jJsonEnvio['ds_numero'] 		    := 0
                jJsonEnvio['nm_cidade'] 		    := EncodeUtf8(AllTrim(SA1->A1_MUN))
                jJsonEnvio['nm_estado'] 		    := EncodeUtf8(AllTrim(SA1->A1_EST))
                If nMultEmail > 0
                    jJsonEnvio['ds_email_cliente']  := EncodeUtf8(SubStr(AllTrim(SA1->A1_EMAIL), 1, nMultEmail))
                    // c�pia de e-mail
                    If !Empty(cEmailCC) .and. cEmailCC != ";"
                        jJsonEnvio['email_cc'] 	    := EncodeUtf8(cEmailCC)
                    EndIf
                Else
                    jJsonEnvio['ds_email_cliente']  := EncodeUtf8(AllTrim(SA1->A1_EMAIL))
                EndIf
                jJsonEnvio['nu_telefone'] 		    := StrTran(StrTran(If(Len(AllTrim(SA1->A1_DDD)) == 3, SubStr(SA1->A1_DDD, 2, 2), AllTrim(SA1->A1_DDD)) + AllTrim(SA1->A1_TEL), "-", ""), " ", "")
                // envia valor m�nimo (neste momento s� valida se o cart�o � valido)
                jJsonEnvio['vl_total'] 			    := 1
                jJsonEnvio['ds_softdescriptor']	    := AllTrim(FWFilName(cEmpAnt, cFilAnt))

                jJsonEnvio['nm_cliente'] 		    := EncodeUtf8(SubStr(AllTrim(SA1->A1_NOME), 1, 40))
                // jJsonEnvio['slug'] 				    := Embaralha(StrTran(cChave, " ", ""), 1)	// Endere�o final do link para pagamento
                jJsonEnvio['slug'] 			        := FwUUIDV4(.T.)	// Endere�o final do link para pagamento
                jJsonEnvio['dt_validade'] 		    := nil						// Validade do link (expirar em uma data)
                jJsonEnvio['nu_max_pagamentos']     := 1            // n�o permite que haja mais de um pagamento ao mesmo link
                jJsonEnvio['tp_quantidade'] 	    := .F.
                
                jJsonEnvio['tp_credito'] 		    := .T.
                jJsonEnvio['tp_pagamento_credito'] 		:= "AV"	    // AV = Avista; PL = Parcelado pela Loja (n�o gera assinatura)
                jJsonEnvio['nu_max_parcelas_credito'] 	:= 1		// cliente pode selecionar no m�ximo em 1x o pagamento
                jJsonEnvio['dia_cobranca_credito'] 		:= Nil		// define o dia do m�s para a cobran�a
                jJsonEnvio['tp_nu_parcela_fixo'] 		:= "S"		// define que o cliente n�o pode alterar o numero de parcelas para pagar (devido ao "de para" com os t�tulos do protheus)

                // endere�o da integra��o
                oRest := FWRest():New(cHost)
                
                // path para gera��o de link de captura
                oRest:SetPath(cPathCaptura)

                // json com os dados de envio
                oRest:SetPostParams(jJsonEnvio:ToJson())
                oRest:SetChkStatus(.T.)

                // tenta efetuar o Post
                If oRest:Post(aHeader)

                    cStatus := "P"  // P=Pendente retorno
                    jJsonRet  := JsonObject():New()
                    jJsonData := JsonObject():New()

                    // Resgata a resposta do JSON
                    jJsonRet:FromJson(DecodeUTF8(oRest:GetResult()))

                    If jJsonRet:HasProperty("data")

                        // dados de retorno
                        jJsonData:FromJson(AllTrim(jJsonRet['data']:ToJson()))

                        // grava status da integra��o
                        Reclock("SZC", .F.)
                            SZC->ZC_STATUSC := cStatus
                        SZC->(MsUnlock())
                        
                        // grava log de captura
                        U_FCLogCap(aDadosLog, "Sucesso no envio de captura de cart�o de cr�dito, aguardando retorno.", cStatus, jJsonEnvio:ToJson(), jJsonData:ToJson(), "")

                        If lBaseProducao
                            // envia e-mail de sucesso
                            MailCliCC(cEmailCad, cEmailCpy, SA1->A1_NOME, cStatus, jJsonData['url_link'])
                        EndIf
                        
                        FwAlertSuccess("Sucesso no envio de captura de cart�o de cr�dito, aguardando retorno.", "Envio de captura de cart�o de cr�dito")

                    Else
                        lRet := .F.
                    EndIf
                    
                Else
                    lRet := .F.
                EndIf

                // falha na integra��o
                If !lRet
                    cStatus := "F"  // F=Falha integra��o
                    jJsonRet := JsonObject():New()

                    // Resgata a resposta do JSON
                    jJsonRet:FromJson(AllTrim(oRest:GetResult()))

                    // c�digo de erro
                    cErro := DecodeUTF8(AllTrim(oRest:GetLastError()))

                    // extrai mensagens do json de retorno
                    cErro += U_FCFormataErrosRetorno(jJsonRet)

                    // grava status da integra��o
                    Reclock("SZC", .F.)
                        SZC->ZC_STATUSC := cStatus
                    SZC->(MsUnlock())
                    
                    // grava log de captura
                    U_FCLogCap(aDadosLog, "Erro no envio de captura de cart�o de cr�dito.", cStatus, jJsonEnvio:ToJson(), jJsonRet:ToJson(), cErro)

                    If lBaseProducao
                        // envia e-mail do erro
                        MailCliCC(cEmailCad, cEmailCpy, SA1->A1_NOME, cStatus, "", cErro)
                    EndIf

                    FwAlertError("Erro no envio de captura de cart�o de cr�dito: " + enter + cErro, "Envio de captura de cart�o de cr�dito")

                    // envia e-mail do erro
                    // U_FCEnvioDeEMail(aDadosLog[1], "CC")
                EndIf

            EndIf
        EndIf
    EndIf

    RestArea(aArea)

Return Nil


/*/{Protheus.doc} MailCliCC
	Envio de e-mail com as informa��es e link para pagamento via cart�o de cr�dito ao cliente
    @type function
	@version 1.0
	@author Daniel Scheeren - Gruppe
	@since 02/06/2022
	@param cEmailCli, character, E-mail do cliente
	@param cNomeCli, character, Nome do cliente
	@param nParcela, numeric, Numero da parcela
	@param nTotParcelas, numeric, Numero total de parcelas
	@param nVlrVenda, numeric, Valor da parcela
	@param cLinkCaptura, character, Link de pagamento
	@return variant, return_description
	/*/
Static Function MailCliCC(cEmailCli, cEmailCliCC, cNomeCli, cStatus, cLinkCaptura, cErro)

    // Local oProcess, oHtml
	// // Local cTelefoneContato := SuperGetMV("FC_CONTTEL", .F., "")
	// // Local cEmailContato    := SuperGetMV("FC_CONTEML", .F., "")
	Local cLogoEmpresa  := SuperGetMV("FC_EMPLOGO", .F., "https://static.fastconnect.com.br/clients/1/images/emails/fast-logo-h-500.png.png")
	// // Local cLogoFast 	   := SuperGetMV("FC_FSTLOGO", .F., "https://static.fastconnect.com.br/clients/1/images/emails/fast-logo-500x175.png.png")
	// // Local aDadosFilial 	   := FWArrFilAtu(cEmpAnt, cFilAnt)
	// // Local cNomeFantasia    := EncodeUtf8(Upper(AllTrim(aDadosFilial[17])))
	// // verifica se � base teste ou produ��o para alterar endpoints
    Local lBaseProducao := Upper(AllTrim(GetSrvProfString("dbalias", ""))) == "SIGAPROD"
    Local cEmail        := ""
    Local cAssunto := "Captura de cart�o de cr�dito - " + AllTrim(cNomeCli)

    Default cErro := ""

    // dados do envio
	If lBaseProducao
    	cEmail    	:= cEmailCli + ";daniel.scheeren@gruppe.com.br"
	Else
    	cEmail    	:= UsrRetMail(RetCodUsr()) + ";daniel.scheeren@gruppe.com.br"
	EndIf
    aToMails := StrTokArr(cEmail,";")
    cBody := ""

    oFile := FWFileReader():New("\workflow\fastconnect\WFFastLinkCapturaCC.html")
    If oFile:Open()
    
        If ! (oFile:EoF())
            cBody := oFile:FullRead()
        EndIf
        
        oFile:Close()
    EndIf

    // substitui dados do arquivo
    // cBody := StrTran(cBody, "%cLogo%", AllTrim(cLogoEmpresa))
    cBody := StrTran(cBody, "%cNomeCliente%", AllTrim(cNomeCli))
    cBody := StrTran(cBody, "%cStatus%", If(cStatus == "P", "Sucesso no envio de link para captura de cart�o de cr�dito.", "Falha no envio de link para captura: " + cErro))
    cBody := StrTran(cBody, "%cLinkCaptura%", If(!Empty(cLinkCaptura), AllTrim(cLinkCaptura), "Link n�o gerado."))
    cBody := StrTran(cBody, "//", "\/\/")

    oMail := SendGrid():New()
	oMail:SendMail(aToMails, cAssunto, FwCutOff(cBody, .F.), Nil, .F.)

Return .T.


