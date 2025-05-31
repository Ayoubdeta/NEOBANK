<?php

require_once 'clsBlock.php';
require_once 'clsTransaction.php';


class Blockchain {
    public $chain;
    public $dbCommand;

    public function __construct($dbCommand) {
        $this->dbCommand = $dbCommand;
        $this->chain = [];
        $this->createGenesisBlock();
    }

    private function createGenesisBlock() {
       
        $genesisBlock = new Block( 0, time(), [], null); 
        $this->chain[] = $genesisBlock;
    }
    
    

    public function getChain() {
        return $this->chain;
    }

    public function getLatestBlock() {
        return end($this->chain);
    }

    public function addBlock($newBlock) {
        $newBlock->previousHash = $this->getLatestBlock()->hash;
        $newBlock->hash = $newBlock->calculateHash();
        array_push($this->chain, $newBlock);
    }

    public function isChainValid() {
        for ($i = 1; $i < count($this->chain); $i++) {
            $currentBlock = $this->chain[$i];
            $previousBlock = $this->chain[$i - 1];

            if ($currentBlock->hash !== $currentBlock->calculateHash()) {
                return false;
            }

            if ($currentBlock->previousHash !== $previousBlock->hash) {
                return false;
            }
        }

        return true;
    }
    

    public function __toString(): string {
        return json_encode($this->chain, JSON_PRETTY_PRINT);
    }


}


    
?>