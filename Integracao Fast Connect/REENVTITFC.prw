#Include "Protheus.ch"

/*/{Protheus.doc} ReenvTitFC
    Reenvio de t�tulos manualmente
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 30/09/2021
    @param nOpc, numeric, Op��o de reenvio (1=Reenviar t�tulo atual selecionado; 2=Reenviar todos os t�tulos com erro)
    @return variant, return_description
    /*/
User Function ReenvTitFC(nOpc)
    
    Local _cAliasTmp := GetNextAlias()
    // boleto ou cart�o de cr�dito
    Local lBoleto    := .T.
    // tipo do t�tulo para grava��o nas tabelas de log
    Local cTipoTit   := ""

    // fecha tabela
	If Select(_cAliasTmp) > 0
		(_cAliasTmp)->(DbCloseArea())
	EndIf

    // dados do t�tulo para grava��o do log
    aDadosLog := {;
        SE1->E1_NUM,;
        SE1->E1_PREFIXO,;
        SE1->E1_PARCELA,;
        SE1->E1_CLIENTE,;
        SE1->E1_LOJA,;
        SE1->E1_TIPO;
    }

    If nOpc != Nil

        // reenvio manual do t�tulo posicionado
        If nOpc == 1

            // verifica se a tabela est� aberta
            If Select("SE1") > 0

                // somente tipos de t�tulos permitidos podem ser enviados
                If AllTrim(SE1->E1_TIPO) $ AllTrim(SuperGetMV("MV_TPTITFC",, ""))

                    // t�tulo com status de erro
                    If SE1->E1_ZSTATFC == 'E'

                        // solicita confirma��o
                        If FWAlertYesNo("Confirma reenvio deste t�tulo para integra��o?")
                            
                            // busca todos os t�tulos
                            _cQuery := " SELECT R_E_C_N_O_ AS RECNO "
                            _cQuery += " FROM " + RetSQLTab("SE1")
                            _cQuery += " WHERE " + RetSQLCond("SE1")
                            _cQuery += " AND E1_NUM = '" + SE1->E1_NUM + "' "
                            _cQuery += " AND E1_PREFIXO = '" + SE1->E1_PREFIXO + "' "
                            _cQuery += " AND E1_CLIENTE = '" + SE1->E1_CLIENTE + "' "
                            _cQuery += " AND E1_LOJA = '" + SE1->E1_LOJA + "' "
                            _cQuery += " AND E1_TIPO = '" + SE1->E1_TIPO + "' "
                            // status de erro no envio
                            _cQuery += " AND E1_ZSTATFC = 'E' "
                            // somente n�o enviados para cobran�a (Excel�ncia)
                            _cQuery += " AND E1_ZSTATEX = ' '   

                            DbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAliasTmp), .F., .T.)

                            // altera status de todos os t�tulos para marcar para reenvio
                            DbSelectArea("SE1")
                            If ! (_cAliasTmp)->(Eof())
                                While ! (_cAliasTmp)->(Eof())
                                    SE1->(DbGoTo((_cAliasTmp)->RECNO))

                                    lBoleto := AllTrim(SE1->E1_TIPO) != "CC"

                                    // tipo do t�tulo para grava��o do log
                                    If lBoleto
                                        cTipoTit  := "BOL"
                                    Else
                                        cTipoTit  := "CC"
                                    EndIf

                                    // n�o reenvia se estiver em cobran�a na Excel�ncia
                                    If Empty(SE1->E1_ZSTATEX)

                                        RecLock("SE1", .F.)
                                        SE1->E1_ZSTATFC := "P"  // Pendente de envio
                                        SE1->(MsUnlock())

                                        // grava log de altera��o
                                        U_FCLog(cTipoTit,;
                                                aDadosLog,;
                                                "Solicitado reenvio do t�tulo com erro manualmente pelo usu�rio " + AllTrim(UsrRetName(RetCodUsr())) + ".",;
                                                "A")
                                        
                                        
                                        // grava log pendente de integra��o
                                        U_FCLogPend(aDadosLog, SE1->E1_VENCREA)
                                    Else
                                        
                                        // grava log de altera��o
                                        U_FCLog(cTipoTit,;
                                                aDadosLog,;
                                                "T�tulo est� em cobran�a pela Excel�ncia, n�o pode ser reenviado para Fast Connect.",;
                                                "E")
                                    EndIf

                                    (_cAliasTmp)->(DbSkip())
                                End

                                FWAlertSuccess("T�tulo(s) adicionado(s) � fila de envio!", "")
                            EndIf
                        EndIf
                    
                    Else
                        FWAlertError("O t�tulo selecionado n�o est� com status de erro, portanto n�o pode ser reenviado!", "REENVTITFC.prw")
                    EndIf
                Else
                    FWAlertError("Somente t�tulos de boleto ou cart�o de cr�dito s�o enviados � Fast Connect!", "REENVTITFC.prw")
                EndIf
            Else
                FWAlertError("Tabela de t�tulo n�o est� aberta!", "REENVTITFC.prw")
            EndIf

        // reenvia todos os t�tulos com erro
        ElseIf nOpc == 2

            // solicita confirma��o
            If FWAlertYesNo("Confirma reenvio de TODOS os t�tulos com erro para integra��o?")

                // busca todos os t�tulos
                _cQuery := " SELECT R_E_C_N_O_ AS RECNO "
                _cQuery += " FROM " + RetSQLTab("SE1")
                _cQuery += " WHERE " + RetSQLCond("SE1")
                // todos os tipos de t�tulos permitidos
                _cQuery += " AND E1_TIPO IN " + FormatIn(AllTrim(SuperGetMV("MV_TPTITFC",, "")), "/")
                // status de erro no envio
                _cQuery += " AND E1_ZSTATFC = 'E' "
                _cQuery += " ORDER BY R_E_C_N_O_ "

                DbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAliasTmp), .F., .T.)

                // altera status de todos os t�tulos para marcar para reenvio
                DbSelectArea("SE1")
                If ! (_cAliasTmp)->(Eof())
                    While ! (_cAliasTmp)->(Eof())
                        SE1->(DbGoTo((_cAliasTmp)->RECNO))

                        lBoleto := AllTrim(SE1->E1_TIPO) != "CC"

                        // tipo do t�tulo para grava��o do log
                        If lBoleto
                            cTipoTit  := "BOL"
                        Else
                            cTipoTit  := "CC"
                        EndIf
                        
                        // n�o reenvia se estiver em cobran�a na Excel�ncia
                        If Empty(SE1->E1_ZSTATEX)
                        
                            RecLock("SE1", .F.)
                            SE1->E1_ZSTATFC := "P"  // Pendente de envio
                            SE1->(MsUnlock())

                            // grava log de altera��o
                            U_FCLog(cTipoTit,;
                                    aDadosLog,;
                                    "Solicitado reenvio de TODOS os t�tulos com erro manualmente pelo usu�rio " + AllTrim(UsrRetName(RetCodUsr())) + ".",;
                                    "A")
                                    
                            // grava log pendente de integra��o
                            U_FCLogPend(aDadosLog, SE1->E1_VENCREA)
                        Else
                                
                            // grava log de altera��o
                            U_FCLog(cTipoTit,;
                                    aDadosLog,;
                                    "T�tulo est� em cobran�a pela Excel�ncia, n�o pode ser reenviado para Fast Connect.",;
                                    "E")
                        EndIf

                        (_cAliasTmp)->(DbSkip())
                    End
                
                    FWAlertSuccess("T�tulos adicionados � fila de envio!", "")
                Else
                    FWAlertError("N�o encontrado t�tulos com erro para reenvio!", "")
                EndIf
            EndIf
            
        EndIf

    Else
        FWAlertError("Op��o n�o informada!", "REENVTITFC.prw")
    EndIf

    // fecha tabela
	If Select(_cAliasTmp) > 0
		(_cAliasTmp)->(DbCloseArea())
	EndIf

Return Nil
