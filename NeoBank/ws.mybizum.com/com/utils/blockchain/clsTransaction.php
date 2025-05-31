<?php

class Transaction
{
    public $sender;
    public $receiver;
    public $amount;

    public function __construct(/*$dbCommand,*/ $sender, $receiver, $amount)
    {
        $this->sender = $sender;
        $this->receiver = $receiver;
        $this->amount = $amount;
    }

    public function saveSQL($blockID)
    {
        try {

            global $dbCommand;
             $xml= $dbCommand->execute('AddTransaction', array($this->sender, $this->receiver, $this->amount, $blockID));
           
            return $xml;


            
        } catch (PDOException $e) {
            echo "Error al guardar la transacción: " . $e->getMessage();
        }
    }

    public function __toString()
    {
        return $this->sender . $this->receiver . $this->amount;
    }
}
?>