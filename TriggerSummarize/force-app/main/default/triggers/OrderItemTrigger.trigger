trigger OrderItemTrigger on OrderItem (after insert, after update, after delete) {

    OrderItemTriggerHandler handler = new OrderItemTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.afterInsert();
        }
        when AFTER_UPDATE {
            handler.afterUpdate();
        }
        when AFTER_DELETE {
            handler.afterDelete();
        }
        
    }

}