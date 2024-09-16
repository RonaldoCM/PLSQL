INSERT INTO ORDERREPOSITORY (
    ORDERREPID,
    STATUSPROCESSAMENTO,
    DATE_PROCESSAMENTO,
    DESCRIPTIONERROR,
    XMLDATA
) VALUES (
    2,
    0,
    NULL,
    NULL,
    '<?xml version="1.0" encoding="UTF-8"?>
<Order>
  <OrderId>2</OrderId>
  <CustomerName>Pedido1</CustomerName>
  <OrderDate>14/09/2024</OrderDate>
  <Items>
    <OrderItem>
      <ProductId>1</ProductId>
      <ProductName>Produto A</ProductName>
      <Quantity>2</Quantity>
	  <Price>19.99</Price>
    </OrderItem>
    <OrderItem>
      <ProductId>1</ProductId>
      <ProductName>Produto B</ProductName>
      <Quantity>3</Quantity>
	  <Price>12.99</Price>
    </OrderItem>
  </Items>
</Order>'
);