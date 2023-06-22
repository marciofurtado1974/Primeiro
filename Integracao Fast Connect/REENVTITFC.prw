#Include "Protheus.ch"

/*/{Protheus.doc} ReenvTitFC
    Reenvio de títulos manualmente
    @type function
    @version 1.0
    @author Daniel Scheeren - Gruppe
    @since 30/09/2021
    @param nOpc, numeric, Opção de reenvio (1=Reenviar título atual selecionado; 2=Reenviar todos os títulos com erro)
    @return variant, return_description
    /*/
User Function ReenvTitFC(nOpc)
    
    Local _cAliasTmp := GetNextAlias()
    // boleto ou cartão de crédito
    Local lBoleto    := .T.
    // tipo do título para gravação nas tabelas de log
    Local cTipoTit   := ""

    // fecha tabela
	If Select(_cAliasTmp) > 0
		(_cAliasTmp)->(DbCloseArea())
	EndIf

    // dados do título para gravação do log
    aDadosLog := {;
        SE1->E1_NUM,;
        SE1->E1_PREFIXO,;
        SE1->E1_PARCELA,;
        SE1->E1_CLIENTE,;
        SE1->E1_LOJA,;
        SE1->E1_TIPO;
    }

    If nOpc != Nil

        // reenvio manual do título posicionado
        If nOpc == 1

            // verifica se a tabela está aberta
            If Select("SE1") > 0

                // somente tipos de títulos permitidos podem ser enviados
                If AllTrim(SE1->E1_TIPO) $ AllTrim(SuperGetMV("MV_TPTITFC",, ""))

                    // título com status de erro
                    If SE1->E1_ZSTATFC == 'E'

                        // solicita confirmação
                        If FWAlertYesNo("Confirma reenvio deste título para integração?")
                            
                            // busca todos os títulos
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
                            // somente não enviados para cobrança (Excelência)
                            _cQuery += " AND E1_ZSTATEX = ' '   

                            DbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAliasTmp), .F., .T.)

                            // altera status de todos os títulos para marcar para reenvio
                            DbSelectArea("SE1")
                            If ! (_cAliasTmp)->(Eof())
                                While ! (_cAliasTmp)->(Eof())
                                    SE1->(DbGoTo((_cAliasTmp)->RECNO))

                                    lBoleto := AllTrim(SE1->E1_TIPO) != "CC"

                                    // tipo do título para gravação do log
                                    If lBoleto
                                        cTipoTit  := "BOL"
                                    Else
                                        cTipoTit  := "CC"
                                    EndIf

                                    // não reenvia se estiver em cobrança na Excelência
                                    If Empty(SE1->E1_ZSTATEX)

                                        RecLock("SE1", .F.)
                                        SE1->E1_ZSTATFC := "P"  // Pendente de envio
                                        SE1->(MsUnlock())

                                        // grava log de alteração
                                        U_FCLog(cTipoTit,;
                                                aDadosLog,;
                                                "Solicitado reenvio do título com erro manualmente pelo usuário " + AllTrim(UsrRetName(RetCodUsr())) + ".",;
                                                "A")
                                        
                                        
                                        // grava log pendente de integração
                                        U_FCLogPend(aDadosLog, SE1->E1_VENCREA)
                                    Else
                                        
                                        // grava log de alteração
                                        U_FCLog(cTipoTit,;
                                                aDadosLog,;
                                                "Título está em cobrança pela Excelência, não pode ser reenviado para Fast Connect.",;
                                                "E")
                                    EndIf

                                    (_cAliasTmp)->(DbSkip())
                                End

                                FWAlertSuccess("Título(s) adicionado(s) à fila de envio!", "")
                            EndIf
                        EndIf
                    
                    Else
                        FWAlertError("O título selecionado não está com status de erro, portanto não pode ser reenviado!", "REENVTITFC.prw")
                    EndIf
                Else
                    FWAlertError("Somente títulos de boleto ou cartão de crédito são enviados à Fast Connect!", "REENVTITFC.prw")
                EndIf
            Else
                FWAlertError("Tabela de título não está aberta!", "REENVTITFC.prw")
            EndIf

        // reenvia todos os títulos com erro
        ElseIf nOpc == 2

            // solicita confirmação
            If FWAlertYesNo("Confirma reenvio de TODOS os títulos com erro para integração?")

                // busca todos os títulos
                _cQuery := " SELECT R_E_C_N_O_ AS RECNO "
                _cQuery += " FROM " + RetSQLTab("SE1")
                _cQuery += " WHERE " + RetSQLCond("SE1")
                // todos os tipos de títulos permitidos
                _cQuery += " AND E1_TIPO IN " + FormatIn(AllTrim(SuperGetMV("MV_TPTITFC",, "")), "/")
                // status de erro no envio
                _cQuery += " AND E1_ZSTATFC = 'E' "
                _cQuery += " ORDER BY R_E_C_N_O_ "

                DbUseArea(.T., 'TOPCONN', TCGENQRY(,,_cQuery), (_cAliasTmp), .F., .T.)

                // altera status de todos os títulos para marcar para reenvio
                DbSelectArea("SE1")
                If ! (_cAliasTmp)->(Eof())
                    While ! (_cAliasTmp)->(Eof())
                        SE1->(DbGoTo((_cAliasTmp)->RECNO))

                        lBoleto := AllTrim(SE1->E1_TIPO) != "CC"

                        // tipo do título para gravação do log
                        If lBoleto
                            cTipoTit  := "BOL"
                        Else
                            cTipoTit  := "CC"
                        EndIf
                        
                        // não reenvia se estiver em cobrança na Excelência
                        If Empty(SE1->E1_ZSTATEX)
                        
                            RecLock("SE1", .F.)
                            SE1->E1_ZSTATFC := "P"  // Pendente de envio
                            SE1->(MsUnlock())

                            // grava log de alteração
                            U_FCLog(cTipoTit,;
                                    aDadosLog,;
                                    "Solicitado reenvio de TODOS os títulos com erro manualmente pelo usuário " + AllTrim(UsrRetName(RetCodUsr())) + ".",;
                                    "A")
                                    
                            // grava log pendente de integração
                            U_FCLogPend(aDadosLog, SE1->E1_VENCREA)
                        Else
                                
                            // grava log de alteração
                            U_FCLog(cTipoTit,;
                                    aDadosLog,;
                                    "Título está em cobrança pela Excelência, não pode ser reenviado para Fast Connect.",;
                                    "E")
                        EndIf

                        (_cAliasTmp)->(DbSkip())
                    End
                
                    FWAlertSuccess("Títulos adicionados à fila de envio!", "")
                Else
                    FWAlertError("Não encontrado títulos com erro para reenvio!", "")
                EndIf
            EndIf
            
        EndIf

    Else
        FWAlertError("Opção não informada!", "REENVTITFC.prw")
    EndIf

    // fecha tabela
	If Select(_cAliasTmp) > 0
		(_cAliasTmp)->(DbCloseArea())
	EndIf

Return Nil
