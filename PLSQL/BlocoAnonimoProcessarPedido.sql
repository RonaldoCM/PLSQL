DECLARE
  -- Variáveis para armazenar o cursor e o resultado da procedure
  CURSOR cur_orders IS
    SELECT ORDERREPID, XMLDATA
    FROM ORDERREPOSITORY
    WHERE STATUSPROCESSAMENTO = 0; -- Processa apenas pedidos não processados
  
  v_order_id NUMBER;
  v_xml_data CLOB;
  v_error_message VARCHAR2(100);
  v_status NUMBER; -- Variável para armazenar o status retornado pela procedure
  
BEGIN
  -- Loop para percorrer os registros
  FOR order_rec IN cur_orders LOOP
    -- Inicializa as variáveis
    v_order_id := order_rec.ORDERREPID;
    v_xml_data := order_rec.XMLDATA;
    
    BEGIN
      -- Chama a procedure com o XML e obtém o status do processamento
      PROCESSAR_XML.PROCESSAR_PEDIDO(v_xml_data, v_status);
      
      -- Verifica o status retornado pela procedure
      IF v_status = 1 THEN
        -- Processado com sucesso
        UPDATE ORDERREPOSITORY
        SET STATUSPROCESSAMENTO = 1, 
            DATE_PROCESSAMENTO = SYSDATE,
            DESCRIPTIONERROR = NULL
        WHERE ORDERREPID = v_order_id;
        COMMIT;
      
      ELSIF v_status = 2 THEN
      -- Erro lógico (exemplo: pedidos sem itens)        
        UPDATE ORDERREPOSITORY
        SET STATUSPROCESSAMENTO = 2,
            DATE_PROCESSAMENTO = SYSDATE,
            DESCRIPTIONERROR = 'Erro lógico no pedido, pedido sem itens.'
        WHERE ORDERREPID = v_order_id;
        COMMIT;
        
       ELSIF v_status = 3 THEN
        -- Erro lógico (exemplo: itens duplicados)
        UPDATE ORDERREPOSITORY
        SET STATUSPROCESSAMENTO = 2, 
            DATE_PROCESSAMENTO = SYSDATE,
            DESCRIPTIONERROR = 'Erro lógico no pedido, como itens duplicados.'
        WHERE ORDERREPID = v_order_id;
        COMMIT;
      END IF;
          
    EXCEPTION
      -- Captura exceções críticas que podem ocorrer durante o processamento
      WHEN OTHERS THEN
        -- Armazena a mensagem de erro no caso de exceção crítica
        v_error_message := SUBSTR(SQLERRM, 1, 100);
        
        -- Atualiza a tabela com erro crítico
        UPDATE ORDERREPOSITORY
        SET STATUSPROCESSAMENTO = 3, 
            DATE_PROCESSAMENTO = SYSDATE,
            DESCRIPTIONERROR = v_error_message
        WHERE ORDERREPID = v_order_id;
        
        -- Rollback em caso de erro
        ROLLBACK;
    END;
  END LOOP;
END;
/

SELECT * FROM ORDERREPOSITORY;
SELECT * FROM ORDERS;
SELECT * FROM ORDERITEMS;

--ORDERS E ORDERITEMS DEVEM SER LIMPAS AO REINICIAR O PROCESSAMENTO, CASO QUEIRA USAR OS MESMOS REGISTROS DA ORDERREPOSITORY
--VOLTAR OS REGISTROS PARA SEREM REPROCESSADOS NA ORIGEM
--UPDATE ORDERREPOSITORY SET STATUSPROCESSAMENTO = 0, DATE_PROCESSAMENTO = NULL, DESCRIPTIONERROR = NULL WHERE ORDERREPID = 1;COMMIT;
--UPDATE ORDERREPOSITORY SET STATUSPROCESSAMENTO = 0, DATE_PROCESSAMENTO = NULL, DESCRIPTIONERROR = NULL WHERE ORDERREPID = 2;COMMIT;
--UPDATE ORDERREPOSITORY SET STATUSPROCESSAMENTO = 0, DATE_PROCESSAMENTO = NULL, DESCRIPTIONERROR = NULL WHERE ORDERREPID = 3;COMMIT;