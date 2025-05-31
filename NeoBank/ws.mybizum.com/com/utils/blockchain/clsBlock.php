<?php

class Block
{
    public $index;
    public $timestamp;
    public $transactions;
    public $previousHash;
    public $hash;

    public function __construct( $index, $timestamp, $transactions, $previousHash = '')
    {
        if (!is_array($transactions)) {
            throw new Exception('Las transacciones deben ser un array.');
        }
    
        $this->transactions = $transactions; 
        $this->index = $index;
        $this->timestamp = $timestamp;
        $this->previousHash = $previousHash;
        $this->hash = $this->calculateHash();
    }
    

    public function calculateHash(): string
    {
        $transactionsArray = array_map(function($tx) {
            return (string)$tx; 
        }, $this->transactions);
    
        return md5($this->index . $this->timestamp . implode('', $transactionsArray) . $this->previousHash);
    }
    
     public function saveSQL()
    {
    try {
        global $dbCommand;

        $xmlBlockResponse = $dbCommand->execute('AddBlock', array($this->hash, $this->previousHash));

        $domBlock = new DOMDocument();
        $domBlock->loadXML($xmlBlockResponse);

        
        $blockID = $dbCommand->execute('GetLastBlockId', array());

        
        $domTransactions = new DOMDocument();
        $transactionsRoot = $domTransactions->createElement('TransactionsResponse');


        foreach ($this->transactions as $transaction) {
            $xmlTransaction = $transaction->saveSQL($blockID);

            $domTx = new DOMDocument();
            $domTx->loadXML($xmlTransaction);

            $importedNode = $domTransactions->importNode($domTx->documentElement, true);
            $transactionsRoot->appendChild($importedNode);
        }

        $domTransactions->appendChild($transactionsRoot);

        $finalDom = new DOMDocument('1.0', 'UTF-8');
        $root = $finalDom->createElement('SaveBlockResponse');

        $importBlock = $finalDom->importNode($domBlock->documentElement, true);
        $root->appendChild($importBlock);

        
        $importTx = $finalDom->importNode($domTransactions->documentElement, true);
        $root->appendChild($importTx);

        $finalDom->appendChild($root);

        return $finalDom->saveXML();

    } catch (PDOException $e) {
        return '<error>Error al guardar el bloque: ' . htmlspecialchars($e->getMessage()) . '</error>';
    }
}

}

?>