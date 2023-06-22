#Include "Protheus.ch"

/*/{Protheus.doc} EMAILFC
	Tela para reenvio de e-mails da integração da Fast Connect
	@type function
	@version 1.0
	@author Daniel Scheeren - Gruppe
	@since 24/09/2021
	@return variant, return_description
	/*/
User Function EMAILFC()

	Local _aCores  := {{ " Z06_STATUS == 'S' ",'ENABLE' },{ " Z06_STATUS <> 'S' ",'DISABLE' }}

	Private cCadastro := "Controle de Emails Fast Connect"
	Private aRotina   := {{ "Pesquisa","AxPesqui", 0 , 1},;
		{ "Visualizar"    , "AxVisual"   , 0 , 2 },;
		{ "Reenvia  Msg." , "U_EMALFCRE" , 0 , 4 }}//,;
		// { "Cons.Log Msg." , "U_CFGA001B" , 0 , 4 } }

	//tabela de Emails
	Dbselectarea('Z06')
	//mostra a tabela Z06
	mBrowse(6, 1, 22, 75, "Z06",,,,,,_aCores )

Return

// envio do EMAIL Posicionado
User Function EMALFCRE
	// area atual
	local _aAreaZ06 := Z06->(GetArea())

	If Z06->Z06_STATUS != "P"

		// mensagem de confirmacao
		If ! MsgYesNo("Confirma o re-envio deste e-mail?")
			Return(.F.)
		EndIf

		// regrava a informação como não Enviado
		Dbselectarea('Z06')
		Reclock("Z06",.F.)
		Z06->Z06_STATUS := 'P'
		// Z06->Z06_DTENVI := CTOD('')
		// Z06->Z06_HRENVI := ' '
		Z06->(msunlock())

		// rotina Generica de Envio do Email
		// StartJob("U_SCHFCEMA()", GetEnvServer(), .T., { FWCodEmp() , FWCodFil() , SC5->C5_NUM , .F. } )
		StartJob("U_SCHFCEMA()", GetEnvServer(), .T., {})
		// msAguarde({|| U_FTSendMail( Z06->(Recno()) )},"Aguarde","Re-enviando o E-mail ...")

	Else
		MsgStop("E-mail já está na fila de envio!")
	EndIf

	// restaura area
	RestArea(_aAreaZ06)

	// mostra o log apos reenvio
	// U_FTConsLog(Z06->Z06_FILIAL,'Z06', Z06->Z06_NCONTR)

Return

// consulta LOG Do Registro de Email
// User Function CFGA001B()
// 	U_FTConsLog(Z06->Z06_FILIAL,'Z06', Z06->Z06_NCONTR) //Mostra os logs Do Registro
// Return
