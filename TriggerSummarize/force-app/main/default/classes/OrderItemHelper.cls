public with sharing class OrderItemHelper {
    public OrderItemHelper() {}

    public static List<Account> summarizeAccounts(Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap){
        List<OrderItem> modifiedOrderItemList = new List<OrderItem>();

        for(OrderItem newOrderItem : newMap.values()){
            OrderItem oldOrderItem = oldMap.get(newOrderItem.Id);

            if((newOrderItem.Quantity != oldOrderItem.Quantity) || (newOrderItem.UnitPrice != oldOrderItem.UnitPrice)){
                modifiedOrderItemList.add(newOrderItem);
            }
        }

        if(!modifiedOrderItemList.isEmpty()){
            return summarizeAccounts(modifiedOrderItemList);
        }
         else return null;

    }

    public static List<Account> summarizeAccounts(List<OrderItem> orderItemList){
        Set<Id> orderIdSet = new Set<Id>();

        for (OrderItem orderItem : orderItemList){ // ITERAÇÃO SOBRE O A LISTA RECEBIDA PELA FUNÇÃO 
            orderIdSet.add(orderItem.OrderId);  // ACESSANDO O ID DO ORDER ATRAVÉS DA LISTA RECEBIDA
        }

        List<Order> orderList = [ // PESQUISA PARA SELECIONAR AS ORDENS DOS ORDEM ITEMS
            SELECT Id, AccountId
            FROM Order
            WHERE Id IN: orderIdSet
        ];

        Set<Id> accountIdSet = new Set<Id>(); // CRIANDO LLISTA PARA CONTAS

        for (Order order : orderList){
            accountIdSet.add(order.AccountId); // SELECIONANDO CONTAS ATRAVÉS DAS ORDENS E ADICIONANDO NA LISTA CRIADA ANTERIORMENTE
        }

        List<AggregateResult> resultList = getAggregateOrderAmount(accountIdSet);

        List<Account> accountList = buildAmountData(resultList);

        return accountList;
    }

    public static List<AggregateResult> getAggregateOrderAmount(Set<Id> accountIdSet){ // RECEBE LISTA DE CONTAS
 
        List<AggregateResult> resultList = [   // FAZ CONSULTAS NAS CONTAS RECEBIDAS
            SELECT AccountId, Status, SUM(TotalAmount) totalAmount
            FROM Order
            WHERE AccountId IN: accountIdSet
            GROUP BY AccountId, Status
        ];

        return resultList; // RETORNA DADOS
    }

    public static List<Account> buildAmountData(List<AggregateResult> resultList){

        Map<String, String> statusToFieldMap = new Map<String, String> {
            'Open' => 'OpenOrderAmount__c',
            'Canceled' => 'CanceledOrderAmount__c',
            'Closed' => 'ClosedOrderAmount__c'
        };

        Map<Id, Account> accountMap = new Map<Id, Account>();

        for (AggregateResult result : resultList){
          Decimal totalAmount = (Decimal)result.get('TotalAmount');
          Id accountId = (Id)result.get('AccountId');
          String status = (String)result.get('Status');
          
          if(accountMap.containsKey(accountId)){
            Account account = accountMap.get(accountId);
            
            if(statusToFieldMap.containsKey(status)){
                account.put(statusToFieldMap.get(status), totalAmount);
            }
          } 
          else {
            Account account = new Account(Id = accountId);
            
            if(statusToFieldMap.containsKey(status)){
                account.put(statusToFieldMap.get(status), totalAmount);
                accountMap.put(accountId, account);
            }
          }
        }
        return accountMap.values();
    }



}