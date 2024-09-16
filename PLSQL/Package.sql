DROP PACKAGE PROCESSAR_XML;

CREATE OR REPLACE PACKAGE PROCESSAR_XML
AS

    PROCEDURE PROCESSAR_PEDIDO ( P_XML_PEDIDO CLOB, p_status OUT NUMBER );    
    
    FUNCTION RETORNAR_ITENS_PEDIDO( p_order_id NUMBER )
    RETURN SYS_REFCURSOR;
    
END PROCESSAR_XML;
/

CREATE OR REPLACE PACKAGE BODY PROCESSAR_XML
AS

    PROCEDURE PROCESSAR_PEDIDO(P_XML_PEDIDO CLOB, p_status OUT NUMBER) IS
    
    v_order_id NUMBER;
    v_item_count NUMBER;
    v_duplicate_count NUMBER;
    
    BEGIN
    
       -- Extrair o OrderId do XML e armazená-lo em uma variável
   SELECT x.OrderId
   INTO v_order_id
   FROM XMLTABLE(
      '/Order'
      PASSING XMLTYPE(P_XML_PEDIDO)
      COLUMNS 
         OrderId NUMBER PATH 'OrderId'
   ) x;
   
     -- Verificar se o XML contém pelo menos um item
  SELECT COUNT(*)
  INTO v_item_count
  FROM XMLTABLE(
    '/Order/Items/OrderItem'
    PASSING XMLTYPE(P_XML_PEDIDO)
    COLUMNS 
       ProductId NUMBER PATH 'ProductId'
  );

  -- Se não houver nenhum item, retorna
  IF v_item_count = 0 THEN
    p_status := 2;
    RETURN;
  END IF;
      
   -- Verificar se há itens duplicados no XML (mesmo ProductId aparece mais de uma vez)
   SELECT COUNT(*)
   INTO v_duplicate_count
   FROM (
      SELECT x.ProductId
      FROM XMLTABLE(
         '/Order/Items/OrderItem'
         PASSING XMLTYPE(P_XML_PEDIDO)
         COLUMNS 
            ProductId NUMBER PATH 'ProductId'
      ) x
      GROUP BY x.ProductId
      HAVING COUNT(x.ProductId) > 1
   );

   IF v_duplicate_count > 0 THEN
                p_status := 3;
                RETURN;
   END IF;
   
          -- Inserir dados na tabela de pedido
   INSERT INTO ORDERS (ORDERID, CUSTOMERNAME, ORDERDATE)
   SELECT x.OrderId,
          x.CustomerName,
          TO_DATE(x.OrderDate, 'DD/MM/YYYY')
   FROM XMLTABLE(
      '/Order'
      PASSING XMLTYPE(P_XML_PEDIDO)
      COLUMNS 
         ORDERID      NUMBER        PATH 'OrderId',
         CUSTOMERNAME VARCHAR2(50)  PATH 'CustomerName',
         ORDERDATE    VARCHAR2(10)  PATH 'OrderDate'
   ) x;

   -- Inserir dados na tabela de itens do pedido
   INSERT INTO ORDERITEMS (ORDERITEMID, ORDERID, PRODUCTNAME, QUANTITY, PRICE)
   SELECT  x.ProductId
          ,v_order_id
          ,x.ProductName
          ,x.Quantity
          ,x.Price
   FROM XMLTABLE(
      '/Order/Items/OrderItem'
      PASSING XMLTYPE(P_XML_PEDIDO)
      COLUMNS          
          ProductId   NUMBER        PATH 'ProductId'
         ,ProductName VARCHAR2(50)  PATH 'ProductName'
         ,Quantity    NUMBER        PATH 'Quantity'
         ,Price       VARCHAR2(10)  PATH 'Price'
   ) x;

   COMMIT;
   
   p_status := 1;
   
    EXCEPTION
    WHEN OTHERS THEN
       p_status := 4;
            RAISE;
    
    END PROCESSAR_PEDIDO;

    FUNCTION RETORNAR_ITENS_PEDIDO(p_order_id NUMBER)
    RETURN SYS_REFCURSOR
    IS
        -- Cursor de retorno
        v_items_cursor SYS_REFCURSOR;
    BEGIN
        -- Abrir o cursor para retornar os itens do pedido
        OPEN v_items_cursor FOR
            SELECT ORDERITEMID, PRODUCTNAME, QUANTITY, PRICE
            FROM ORDERITEMS
            WHERE ORDERID = p_order_id;
    
        -- Retornar o cursor com os dados
        RETURN v_items_cursor;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Se não encontrar nenhum item, lançar uma exceção
            RAISE_APPLICATION_ERROR(-20001, 'Nenhum item encontrado para o pedido ' || p_order_id);
        WHEN OTHERS THEN
            -- Tratamento geral de erros
            RAISE_APPLICATION_ERROR(-20002, 'Erro ao buscar itens do pedido: ' || SQLERRM);
    END RETORNAR_ITENS_PEDIDO;
    
END PROCESSAR_XML;
/