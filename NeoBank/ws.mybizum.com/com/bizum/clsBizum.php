<?php
class clsBizum {
    private $dbCommand;

    public function __construct($dbCommand) {
        $this->dbCommand = $dbCommand;
    }

    
    public function checkBalance($username) {
        
        $result = $this->dbCommand->execute('sp_get_user_balance', [$username]);
        return $result !== false ? $result : null;
    }
    
public function getBalance($connectionId) {
    $result = $this->checkBalance($connectionId);

    if (!is_array($result) || !isset($result[0]['XmlResult'])) {
        
        return $this->generateErrorResponse("Error al obtener el balance.");
    }
    return $result[0]['XmlResult'];
}

        

    // NO VA
    private function generateErrorResponse($message) {
        return "<UserBalance><Error>$message</Error></UserBalance>";
    }


    public function getTransactionsHistory($username) {
    
        $result = $this->dbCommand->execute('GetUserTransactionsHistory', [$username]);

        if ($result === false) {
            return $this->generateErrorResponse("No se pudo obtener el historial de transacciones.");
        }

        return $result;
    }

    public function getLastTransactions($username) {
    // Intentamos ejecutar el procedimiento almacenado
        $result = $this->dbCommand->execute('GetUserLastTransaction', [$username]);

        if ($result === false) {
            return $this->generateErrorResponse("No se pudo obtener el historial de transacciones.");
        }
        header("Content-Type: application/xml; charset=UTF-8");
        return $result;
    }
    
    
    public function getActiveUsernames() {
        // Intentamos ejecutar el procedimiento almacenado
        $result = $this->dbCommand->execute('GetActiveUserUsernames', []);

        if ($result === false) {
            return $this->generateErrorResponse("No se pudo obtener la lista de usuarios activos.");
        }
        header("Content-Type: application/xml; charset=UTF-8");
        return $result;
    }

    public function enviarBizum($sender, $receiver, $amount) {
        if (empty($sender) || empty($receiver) || empty($amount)) {
            header("Content-Type: application/xml; charset=UTF-8");
            echo $this->generateXmlResponse(1, "Faltan parámetros necesarios.");
            exit;
        }

        $receiver = trim(strtolower($receiver));
        $receiverCheck = $this->dbCommand->execute('CheckReceiverExists', [$receiver]);

        if ($receiverCheck !== '1') {
            header("Content-Type: application/xml; charset=UTF-8");
            echo $this->generateXmlResponse(1, "El usuario receptor no existe.");
            exit;
        }

        try {
            $myBlockchain = new Blockchain($this->dbCommand);
            $tx = new Transaction($sender, $receiver, $amount);
            $block = new Block(1, time(), [$tx]);
            $myBlockchain->addBlock($block);

            header("Content-Type: application/xml; charset=UTF-8");

            if ($myBlockchain->isChainValid()) {
                echo $block->saveSQL();
            } else {
                echo $this->generateXmlResponse(1, "La blockchain no es válida.");
            }
        } catch (Exception $e) {
            header("Content-Type: application/xml; charset=UTF-8");
            echo $this->generateXmlResponse(1, $e->getMessage());
        }
        exit;
    }



















    


    
    // tESTEO
    private function generateXmlResponse($status, $message) {
        return "<ws_response><head><status>$status</status></head><body><message>" . htmlspecialchars($message) . "</message></body></ws_response>";
    }

    




    
}
?>