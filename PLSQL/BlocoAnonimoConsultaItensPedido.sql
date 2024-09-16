--HABILITA O SERVEROUTPUT DO SQLDEVELOPER
SET SERVEROUTPUT ON;


---CONSULTA ITENS POR PEDIDO
DECLARE
    v_items SYS_REFCURSOR;
    v_orderitemid NUMBER;
    v_productname VARCHAR2(50);
    v_quantity NUMBER;
    v_price VARCHAR2(10);
BEGIN
    -- Chama a função que retorna o cursor com os itens do pedido
    v_items := PROCESSAR_XML.RETORNAR_ITENS_PEDIDO(1);
    
    -- Loop para percorrer os itens do pedido e exibir os detalhes
    LOOP
        -- Buscar os dados do cursor em variáveis locais
        FETCH v_items INTO v_orderitemid, v_productname, v_quantity, v_price;
        
        -- Sair do loop quando não houver mais registros
        EXIT WHEN v_items%NOTFOUND;
        
        -- Exibir os valores dos itens do pedido
        DBMS_OUTPUT.PUT_LINE('Item ID: ' || v_orderitemid || ', Produto: ' || v_productname || 
                             ', Quantidade: ' || v_quantity || ', Preço: ' || v_price);
    END LOOP;
    
    -- Fecha o cursor após a iteração
    CLOSE v_items;
END;
/